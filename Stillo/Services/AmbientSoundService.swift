import AVFoundation
import os.log

// MARK: - AmbientSoundService

/// Менеджер единственного фонового трека (научно обоснованный коричневый шум).
///
/// Коричневый шум (brown / Brownian noise):
/// — Энергия спадает пространственно как 1/f², что даёт глубокий, мягкий звук.
/// — Клинически показан для снижения тревожности и помощи при панических атаках
///   (Söderlund et al., 2007; Rausch et al., 2014).
/// — В отличие от белого шума, не содержит высоких частот, раздражающих при стрессе.
///
/// Архитектура — МАКСИМАЛЬНАЯ ПРОСТОТА:
/// 1. Один файл: `brown_noise.mp3` в бандле.
/// 2. Один AVAudioPlayer, удерживаемый как strong property этого @Observable класса.
/// 3. AVAudioSession `.playback + .mixWithOthers` — звук не конфликтует с голосом.
/// 4. numberOfLoops = -1 — бесконечный цикл.
/// 5. Сессия НИКОГДА не деактивируется.

@Observable
@MainActor
final class AmbientSoundService {

    // MARK: - Constants

    /// Имя файла в бандле (без расширения). Пользователь добавит brown_noise.mp3.
    static let fileName = "brown_noise"

    // MARK: - Observable State

    /// Играет ли фоновый звук прямо сейчас.
    private(set) var isPlaying = false

    /// Громкость 0.0–1.0. Сохраняется в UserDefaults.
    var volume: Double {
        didSet {
            let clamped = max(0, min(1, volume))
            if volume != clamped { volume = clamped }
            player?.volume = Float(volume)
            UserDefaults.standard.set(volume, forKey: Self.volumeKey)
        }
    }

    /// Файл доступен в бандле?
    private(set) var isFileAvailable = false

    // MARK: - Init

    init() {
        let saved = UserDefaults.standard.double(forKey: Self.volumeKey)
        self.volume = saved > 0 ? saved : 0.5

        // Сразу проверяем наличие файла
        if let url = Self.locateFile() {
            self.fileURL = url
            self.isFileAvailable = true
            Self.log.info("✅ Found: \(url.lastPathComponent)")
        } else {
            self.fileURL = nil
            self.isFileAvailable = false
            Self.log.error("❌ \(Self.fileName).mp3 NOT found in bundle")
            Self.dumpBundleMP3s()
        }
    }

    // MARK: - Public API

    /// Включить фоновый звук. Если уже играет — ничего не делает.
    func play() {
        guard !isPlaying else { return }

        guard let url = fileURL else {
            Self.log.error("Cannot play: file not found")
            return
        }

        do {
            // 1. Настроить сессию ПЕРЕД созданием плеера
            try Self.configureSession()

            // 2. Создать плеер
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1          // бесконечный цикл
            p.volume = Float(volume)      // применить текущую громкость
            p.prepareToPlay()

            // 3. Воспроизвести
            let ok = p.play()
            Self.log.info("play() returned \(ok), duration=\(p.duration)s, volume=\(p.volume)")

            if !ok {
                // Единственная попытка восстановить
                Self.log.warning("play() returned false, retrying")
                try Self.configureSession()
                _ = p.play()
            }

            // 4. STRONG reference — плеер живёт пока живёт этот сервис
            self.player = p
            self.isPlaying = true

        } catch {
            Self.log.error("Failed to play: \(error.localizedDescription)")
        }
    }

    /// Остановить фоновый звук.
    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        Self.log.info("Stopped ambient sound")
    }

    /// Toggle: играет → стоп, стоит → играть.
    func toggle() {
        if isPlaying { stop() } else { play() }
    }

    /// Восстановить воспроизведение после того, как голосовой сервис
    /// переключил AVAudioSession на .spokenAudio + .duckOthers.
    /// Вызывается из VoiceBankService / AudioGuideService / OpenAITTSService.
    func recoverSession() {
        guard isPlaying, let p = player else { return }
        Self.log.info("Recovering session after voice playback")

        do {
            try Self.configureSession()
        } catch {
            Self.log.error("recoverSession failed: \(error)")
        }

        // Если плеер был прерван — перезапустить
        if !p.isPlaying {
            p.volume = Float(volume)
            let ok = p.play()
            Self.log.info("Resumed player after recovery, play()=\(ok)")
        }
    }

    // MARK: - Computed (для обратной совместимости с SettingsView / ProfileHubView)

    /// Обратная совместимость: раньше проверялся isAnythingPlaying
    var isAnythingPlaying: Bool { isPlaying }

    // MARK: - Private

    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "Ambient")
    private static let volumeKey = "ambient_volume"

    /// Сильная ссылка на плеер. НЕ @ObservationIgnored — нам не нужно его наблюдать,
    /// но мы и не используем access/withMutation вручную. @Observable видит это как
    /// обычный stored property. Безопасно.
    private var player: AVAudioPlayer?

    /// Закэшированный URL файла в бандле.
    private let fileURL: URL?

    // MARK: - Audio Session

    /// .playback — звук продолжает играть при блокировке экрана.
    /// .mixWithOthers — не прерывает голосовое сопровождение.
    private static func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
        log.info("Session configured: .playback + .mixWithOthers")
    }

    // MARK: - File Lookup

    /// Ищет MP3 в бандле несколькими стратегиями.
    private static func locateFile() -> URL? {
        let bundle = Bundle.main
        let name = Self.fileName

        // Стратегия 1: flat copy (Xcode default для PBXFileSystemSynchronizedRootGroup)
        if let url = bundle.url(forResource: name, withExtension: "mp3") {
            return url
        }

        // Стратегия 2: Subdirectory Audio/
        if let url = bundle.url(forResource: name, withExtension: "mp3", subdirectory: "Audio") {
            return url
        }

        // Стратегия 3: Subdirectory Sounds/
        if let url = bundle.url(forResource: name, withExtension: "mp3", subdirectory: "Sounds") {
            return url
        }

        // Стратегия 4: Subdirectory Resources/Audio/
        if let url = bundle.url(forResource: name, withExtension: "mp3", subdirectory: "Resources/Audio") {
            return url
        }

        // Стратегия 5: Recursive search (последний шанс)
        if let resourcePath = bundle.resourcePath {
            let target = "\(name).mp3"
            if let enumerator = FileManager.default.enumerator(atPath: resourcePath) {
                while let file = enumerator.nextObject() as? String {
                    if file.hasSuffix(target) {
                        return URL(fileURLWithPath: resourcePath).appendingPathComponent(file)
                    }
                }
            }
        }

        return nil
    }

    /// Дебаг: вывести все MP3 в бандле
    private static func dumpBundleMP3s() {
        guard let path = Bundle.main.resourcePath else { return }
        var files: [String] = []
        if let enumerator = FileManager.default.enumerator(atPath: path) {
            while let f = enumerator.nextObject() as? String {
                if f.hasSuffix(".mp3") {
                    files.append(f)
                }
            }
        }
        log.info("All MP3 in bundle (\(files.count)): \(files.joined(separator: ", "))")
    }
}
