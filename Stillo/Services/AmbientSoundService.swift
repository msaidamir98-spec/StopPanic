import AVFoundation
import os.log

// MARK: - AmbientSoundService

/// Глобальный аудио-менеджер фоновых звуков (Singleton-like через AppCoordinator).
///
/// Архитектура:
/// 1. Enum `SoundTrack` — каталог треков. Файлы кладутся в бандл вручную.
/// 2. Один AVAudioPlayer (numberOfLoops = -1) — бесконечный цикл.
/// 3. AVAudioSession `.playback + .mixWithOthers` через AudioSessionManager.
/// 4. Выбранный трек и громкость сохраняются в UserDefaults.
/// 5. Музыка НЕ прерывается при переходах между экранами.
/// 6. `playSelectedTrack()` — вызывается из SOS для мгновенного старта.

@Observable
@MainActor
final class AmbientSoundService {

    // MARK: - Sound Track Catalog

    /// Каталог доступных треков.
    /// Пользователь сам кладёт реальные файлы (.mp3/.wav/.m4a) в бандл.
    /// Имя файла ДОЛЖНО совпадать с `rawValue` (например `rain_ambient.mp3`).
    enum SoundTrack: String, CaseIterable, Identifiable {
        case rainAmbient    = "rain_ambient"
        case forestCalm     = "forest_calm"
        case oceanWaves     = "ocean_waves"
        case softMelody     = "soft_melody"
        case brownNoise     = "brown_noise"

        var id: String { rawValue }

        /// Локализованное имя
        var nameKey: String {
            switch self {
            case .rainAmbient:  "sound.rain_ambient"
            case .forestCalm:   "sound.forest_calm"
            case .oceanWaves:   "sound.ocean_waves"
            case .softMelody:   "sound.soft_melody"
            case .brownNoise:   "sound.brown_noise"
            }
        }

        /// Краткое описание
        var descriptionKey: String {
            switch self {
            case .rainAmbient:  "sound.rain_ambient_desc"
            case .forestCalm:   "sound.forest_calm_desc"
            case .oceanWaves:   "sound.ocean_waves_desc"
            case .softMelody:   "sound.soft_melody_desc"
            case .brownNoise:   "sound.brown_noise_desc"
            }
        }

        /// SF Symbol
        var icon: String {
            switch self {
            case .rainAmbient:  "cloud.rain.fill"
            case .forestCalm:   "leaf.fill"
            case .oceanWaves:   "water.waves"
            case .softMelody:   "music.note"
            case .brownNoise:   "waveform.path"
            }
        }

        /// Цвет для UI
        var colorName: String {
            switch self {
            case .rainAmbient:  "blue"
            case .forestCalm:   "green"
            case .oceanWaves:   "teal"
            case .softMelody:   "purple"
            case .brownNoise:   "brown"
            }
        }
    }

    // MARK: - State

    /// Играет ли прямо сейчас
    private(set) var isPlaying = false

    /// Текущий выбранный трек (сохраняется в UserDefaults)
    var selectedTrack: SoundTrack {
        didSet {
            UserDefaults.standard.set(selectedTrack.rawValue, forKey: Self.trackKey)
            if isPlaying { stop(); play() }
        }
    }

    /// Громкость 0.0–1.0 (сохраняется глобально)
    var volume: Double {
        didSet {
            let clamped = max(0, min(1, volume))
            if volume != clamped { volume = clamped }
            player?.volume = Float(volume)
            UserDefaults.standard.set(volume, forKey: Self.volumeKey)
        }
    }

    /// Треки, найденные в бандле
    private(set) var availableTracks: [SoundTrack] = []

    // MARK: - Compat

    var isAnythingPlaying: Bool { isPlaying }
    var isFileAvailable: Bool { !availableTracks.isEmpty }

    // MARK: - Keys

    private static let trackKey  = "ambient_selected_track"
    private static let volumeKey = "ambient_volume"

    // MARK: - Init

    init() {
        let savedRaw = UserDefaults.standard.string(forKey: Self.trackKey) ?? ""
        let track = SoundTrack(rawValue: savedRaw) ?? .rainAmbient
        self._selectedTrack = track

        let savedVol = UserDefaults.standard.double(forKey: Self.volumeKey)
        self._volume = savedVol > 0 ? savedVol : 0.6

        self.availableTracks = SoundTrack.allCases.filter { Self.locateFile($0) != nil }
        Self.log.info("Ambient: available=\(self.availableTracks.map(\.rawValue))")
    }

    // MARK: - Public API

    /// Начать воспроизведение выбранного трека (бесконечный цикл)
    func play() {
        guard !isPlaying else { return }
        guard let url = Self.locateFile(selectedTrack) else {
            Self.log.error("File not found: \(self.selectedTrack.rawValue)")
            return
        }

        do {
            AudioSessionManager.configureForAmbient()
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1
            p.volume = Float(volume)
            p.prepareToPlay()
            let ok = p.play()
            Self.log.info("play(\(self.selectedTrack.rawValue))=\(ok), dur=\(p.duration)s")

            if !ok {
                AudioSessionManager.configureForAmbient()
                _ = p.play()
            }

            self.player = p
            self.isPlaying = true
        } catch {
            Self.log.error("Play error: \(error.localizedDescription)")
        }
    }

    /// Остановить воспроизведение
    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }

    /// Toggle play/stop
    func toggle() {
        isPlaying ? stop() : play()
    }

    /// Мгновенный старт выбранного трека — вызывается из SOS
    func playSelectedTrack() {
        if isPlaying { stop() }
        play()
    }

    /// Воспроизвести конкретный трек для превью в настройках (5 секунд)
    func preview(_ track: SoundTrack) {
        previewTask?.cancel()
        previewPlayer?.stop()

        guard let url = Self.locateFile(track) else { return }
        do {
            AudioSessionManager.configureForAmbient()
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = 0
            p.volume = Float(volume)
            p.prepareToPlay()
            _ = p.play()
            self.previewPlayer = p
            self.previewingTrack = track

            previewTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                self.stopPreview()
            }
        } catch {
            Self.log.error("Preview error: \(error.localizedDescription)")
        }
    }

    /// Остановить превью
    func stopPreview() {
        previewTask?.cancel()
        previewTask = nil
        previewPlayer?.stop()
        previewPlayer = nil
        previewingTrack = nil
    }

    /// Какой трек сейчас на превью (nil если нет)
    private(set) var previewingTrack: SoundTrack?

    /// Восстановить после голосового гида
    func recoverSession() {
        guard isPlaying, let p = player else { return }
        AudioSessionManager.recoverAfterSpeech()
        if !p.isPlaying {
            p.volume = Float(volume)
            _ = p.play()
            Self.log.info("Resumed after voice recovery")
        }
    }

    // MARK: - Private

    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "Ambient")
    private var player: AVAudioPlayer?
    private var previewPlayer: AVAudioPlayer?
    private var previewTask: Task<Void, Never>?

    // MARK: - File Lookup

    /// Ищет реальный аудиофайл в бандле. Поддерживает .mp3, .wav, .m4a.
    private static func locateFile(_ track: SoundTrack) -> URL? {
        let name = track.rawValue
        let extensions = ["mp3", "wav", "m4a", "aac", "caf"]
        let subdirs: [String?] = [nil, "Audio", "Sounds", "Resources/Audio"]

        for ext in extensions {
            for subdir in subdirs {
                if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdir) {
                    return url
                }
            }
        }

        // Recursive fallback
        if let resourcePath = Bundle.main.resourcePath {
            let fm = FileManager.default
            if let enumerator = fm.enumerator(atPath: resourcePath) {
                while let file = enumerator.nextObject() as? String {
                    for ext in extensions {
                        if file.hasSuffix("\(name).\(ext)") {
                            return URL(fileURLWithPath: resourcePath).appendingPathComponent(file)
                        }
                    }
                }
            }
        }
        return nil
    }
}
