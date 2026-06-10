import AVFoundation
import os.log

// MARK: - AmbientSoundService

/// Глобальный аудио-менеджер фоновых звуков уровня Calm/Headspace.
///
/// Архитектура:
/// ┌─────────────────────────────────────────────────────────────┐
/// │  SoundTrack — каталог из 6 премиальных треков              │
/// │  SoundCategory — Nature / Melody (для группировки в UI)    │
/// │  AVAudioPlayer (numberOfLoops = -1) — бесконечный цикл     │
/// │  AVAudioSession: .mixWithOthers → ambient                  │
/// │                  .duckOthers   → голос поверх ambient       │
/// │  Живёт глобально через AppCoordinator → не прерывается      │
/// │  playSelectedTrack() → мгновенный старт из SOS             │
/// │  play() → также вызывается из BreathingSessionView          │
/// └─────────────────────────────────────────────────────────────┘

@Observable
@MainActor
final class AmbientSoundService {

    // MARK: - Sound Category

    enum SoundCategory: String, CaseIterable, Identifiable {
        case nature   = "nature"
        case melody   = "melody"

        var id: String { rawValue }

        var nameKey: String {
            switch self {
            case .nature: "sound.category_nature"
            case .melody: "sound.category_melody"
            }
        }

        var icon: String {
            switch self {
            case .nature: "leaf.circle.fill"
            case .melody: "music.note.list"
            }
        }
    }

    // MARK: - Sound Track Catalog

    /// 6 премиальных треков. Файл в бандле ДОЛЖЕН совпадать с rawValue.
    /// Формат: AAC .m4a (128kbps) в Resources/Audio/.
    enum SoundTrack: String, CaseIterable, Identifiable {
        case rainAmbient       = "rain_ambient"
        case forestCalm        = "forest_calm"
        case calmMelody       = "calm_melody"
        case pianoMeditation   = "piano_meditation"
        case fluteMeditation   = "flute_meditation"
        case underwaterAmbience = "underwater_ambience"

        var id: String { rawValue }

        var category: SoundCategory {
            switch self {
            case .rainAmbient, .forestCalm, .underwaterAmbience:
                .nature
            case .pianoMeditation, .fluteMeditation, .calmMelody:
                .melody
            }
        }

        var nameKey: String {
            switch self {
            case .rainAmbient:      "sound.rain_ambient"
            case .forestCalm:       "sound.forest_calm"
            case .calmMelody:       "sound.calm_melody"
            case .pianoMeditation:  "sound.piano_meditation"
            case .fluteMeditation:  "sound.flute_meditation"
            case .underwaterAmbience: "sound.underwater_ambience"
            }
        }

        var descriptionKey: String {
            switch self {
            case .rainAmbient:      "sound.rain_ambient_desc"
            case .forestCalm:       "sound.forest_calm_desc"
            case .calmMelody:       "sound.calm_melody_desc"
            case .pianoMeditation:  "sound.piano_meditation_desc"
            case .fluteMeditation:  "sound.flute_meditation_desc"
            case .underwaterAmbience: "sound.underwater_ambience_desc"
            }
        }

        var icon: String {
            switch self {
            case .rainAmbient:      "cloud.rain.fill"
            case .forestCalm:       "leaf.fill"
            case .calmMelody:       "music.quarternote.3"
            case .pianoMeditation:  "pianokeys"
            case .fluteMeditation:  "wand.and.stars"
            case .underwaterAmbience: "drop.circle.fill"
            }
        }

        /// Группировка по категориям для UI
        static func tracks(for category: SoundCategory) -> [SoundTrack] {
            allCases.filter { $0.category == category }
        }
    }

    // MARK: - Published State

    /// Играет ли прямо сейчас
    private(set) var isPlaying = false

    /// Текущий выбранный трек (сохраняется в UserDefaults)
    var selectedTrack: SoundTrack {
        didSet {
            UserDefaults.standard.set(selectedTrack.rawValue, forKey: Keys.track)
            if isPlaying { crossfadeTo(selectedTrack) }
        }
    }

    /// Громкость 0.0–1.0 (сохраняется глобально)
    var volume: Double {
        didSet {
            let clamped = min(1, max(0, volume))
            if volume != clamped { volume = clamped }
            player?.volume = Float(volume)
            previewPlayer?.volume = Float(volume)
            UserDefaults.standard.set(volume, forKey: Keys.volume)
        }
    }

    /// Треки, найденные в бандле
    private(set) var availableTracks: [SoundTrack] = []

    /// Какой трек на превью (nil если нет)
    private(set) var previewingTrack: SoundTrack?

    // MARK: - Convenience

    var isAnythingPlaying: Bool { isPlaying }
    var isFileAvailable: Bool { !availableTracks.isEmpty }

    /// Доступные треки по категории
    func available(in category: SoundCategory) -> [SoundTrack] {
        availableTracks.filter { $0.category == category }
    }

    // MARK: - Keys

    private enum Keys {
        static let track  = "ambient_selected_track"
        static let volume = "ambient_volume"
    }

    // MARK: - Init

    init() {
        let savedRaw = UserDefaults.standard.string(forKey: Keys.track) ?? ""
        let track = SoundTrack(rawValue: savedRaw) ?? .rainAmbient
        self._selectedTrack = track

        // Отличаем «ключ отсутствует» (первый запуск → дефолт 0.6) от
        // сознательно сохранённого 0 — иначе выставленный пользователем
        // ноль сбрасывался на 0.6 после рестарта.
        if UserDefaults.standard.object(forKey: Keys.volume) == nil {
            self._volume = 0.6
        } else {
            self._volume = UserDefaults.standard.double(forKey: Keys.volume)
        }

        // Migrate from old brown_noise selection
        if savedRaw == "brown_noise" {
            self._selectedTrack = .rainAmbient
            UserDefaults.standard.set("rain_ambient", forKey: Keys.track)
        }

        self.availableTracks = SoundTrack.allCases.filter {
            Self.locateFile($0) != nil
        }
        Self.log.info("Ambient: available=\(self.availableTracks.map(\.rawValue))")
    }

    // MARK: - Playback API

    /// Начать воспроизведение выбранного трека (бесконечный цикл).
    /// Вызывается из SoundscapeView, BreathingSessionView, SOS.
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
            p.enableRate = true
            p.prepareToPlay()
            _ = p.play()
            self.player = p
            self.isPlaying = true
            Self.log.info("▶ play(\(self.selectedTrack.rawValue)) dur=\(p.duration)s")
        } catch {
            Self.log.error("Play error: \(error.localizedDescription)")
        }
    }

    /// Остановить воспроизведение с fade-out (0.3s)
    func stop() {
        guard let p = player else {
            isPlaying = false
            return
        }
        duckTask?.cancel(); duckTask = nil
        fadeOut(p, duration: 0.3, task: &mainFadeTask) {
            p.stop()
            Task { @MainActor [weak self] in
                self?.player = nil
                self?.isPlaying = false
            }
        }
    }

    /// Toggle play/stop
    func toggle() {
        isPlaying ? stop() : play()
    }

    /// Мгновенный старт — вызывается из SOS и Meditation
    func playSelectedTrack() {
        crossfadeTask?.cancel(); crossfadeTask = nil
        mainFadeTask?.cancel(); mainFadeTask = nil
        duckTask?.cancel(); duckTask = nil
        previewTask?.cancel(); previewTask = nil
        previewPlayer?.stop(); previewPlayer = nil; previewingTrack = nil
        if let p = player { p.stop() }
        player = nil
        isPlaying = false
        play()
    }

    // MARK: - Crossfade

    /// Плавная смена трека без разрыва
    private func crossfadeTo(_ track: SoundTrack) {
        guard let url = Self.locateFile(track) else { return }
        guard let oldPlayer = player else { play(); return }

        do {
            AudioSessionManager.configureForAmbient()
            let newP = try AVAudioPlayer(contentsOf: url)
            newP.numberOfLoops = -1
            newP.volume = 0
            newP.enableRate = true
            newP.prepareToPlay()
            _ = newP.play()

            // Fade old out, new in (0.5s)
            let steps = 20
            let interval = 0.5 / Double(steps)
            let targetVol = Float(volume)

            crossfadeTask?.cancel()
            crossfadeTask = Task { @MainActor in
                for i in 1...steps {
                    guard !Task.isCancelled else { return }
                    try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))
                    let progress = Float(i) / Float(steps)
                    oldPlayer.volume = targetVol * (1 - progress)
                    newP.volume = targetVol * progress
                }
                oldPlayer.stop()
                self.player = newP
            }
        } catch {
            Self.log.error("Crossfade error: \(error.localizedDescription)")
        }
    }

    // MARK: - Preview (5 sec sample in settings)

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

    func stopPreview() {
        previewTask?.cancel()
        previewTask = nil
        if let p = previewPlayer {
            fadeOut(p, duration: 0.2, task: &previewFadeTask) {
                p.stop()
                Task { @MainActor [weak self] in
                    self?.previewPlayer = nil
                    self?.previewingTrack = nil
                }
            }
        } else {
            previewingTrack = nil
        }
    }

    // MARK: - Voice Guide Ducking

    /// Вызывается перед голосовым гидом — приглушает ambient до 20%
    func duckForVoice() {
        guard isPlaying, let p = player else { return }
        let duckedVol = Float(volume) * 0.2
        AudioSessionManager.configureForSpeechOverAmbient()
        fadeVolume(p, to: duckedVol, duration: 0.3, task: &duckTask)
        if !p.isPlaying { _ = p.play() }
        Self.log.info("🔉 Ducked ambient to \(duckedVol)")
    }

    /// Вызывается после голосового гида — восстанавливает громкость
    func unduck() {
        guard isPlaying, let p = player else { return }
        AudioSessionManager.configureForAmbient()
        fadeVolume(p, to: Float(volume), duration: 0.5, task: &duckTask)
        if !p.isPlaying { _ = p.play() }
        Self.log.info("🔊 Restored ambient to \(self.volume)")
    }

    /// Legacy compat
    func recoverSession() { unduck() }

    // MARK: - Private

    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "Ambient")
    private var player: AVAudioPlayer?
    private var previewPlayer: AVAudioPlayer?
    private var previewTask: Task<Void, Never>?
    private var crossfadeTask: Task<Void, Never>?
    private var mainFadeTask: Task<Void, Never>?
    private var previewFadeTask: Task<Void, Never>?
    private var duckTask: Task<Void, Never>?

    // MARK: - Fade Helpers

    private func fadeOut(
        _ player: AVAudioPlayer,
        duration: Double,
        task: inout Task<Void, Never>?,
        completion: @escaping @Sendable () -> Void
    ) {
        let steps = 15
        let interval = duration / Double(steps)
        let startVol = player.volume

        task?.cancel()
        task = Task { @MainActor in
            for i in 1...steps {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))
                player.volume = startVol * (1 - Float(i) / Float(steps))
            }
            guard !Task.isCancelled else { return }
            completion()
        }
    }

    private func fadeVolume(
        _ player: AVAudioPlayer,
        to target: Float,
        duration: Double,
        task: inout Task<Void, Never>?
    ) {
        let steps = 15
        let interval = duration / Double(steps)
        let startVol = player.volume

        task?.cancel()
        task = Task { @MainActor in
            for i in 1...steps {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))
                let progress = Float(i) / Float(steps)
                player.volume = startVol + (target - startVol) * progress
            }
            guard !Task.isCancelled else { return }
            player.volume = target
        }
    }

    // MARK: - File Lookup

    static func locateFile(_ track: SoundTrack) -> URL? {
        let name = track.rawValue
        let extensions = ["mp3", "m4a", "wav", "aac", "caf"]
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
