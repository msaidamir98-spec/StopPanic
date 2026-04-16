import AVFoundation
import os.log

// MARK: - AmbientSoundService

/// Глобальный аудио-менеджер фоновых звуков уровня Calm/Headspace.
///
/// Архитектура:
/// ┌─────────────────────────────────────────────────────────────┐
/// │  SoundTrack — каталог из 5 премиальных треков              │
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

    /// 5 премиальных треков. Файл в бандле ДОЛЖЕН совпадать с rawValue.
    /// Пользователь кладёт .mp3 / .wav / .m4a в Resources/Audio/.
    enum SoundTrack: String, CaseIterable, Identifiable {
        case rainAmbient       = "rain_ambient"
        case forestCalm        = "forest_calm"
        case oceanWaves        = "ocean_waves"
        case pianoMeditation   = "piano_meditation"
        case fluteMeditation   = "flute_meditation"

        var id: String { rawValue }

        var category: SoundCategory {
            switch self {
            case .rainAmbient, .forestCalm, .oceanWaves:
                .nature
            case .pianoMeditation, .fluteMeditation:
                .melody
            }
        }

        var nameKey: String {
            switch self {
            case .rainAmbient:      "sound.rain_ambient"
            case .forestCalm:       "sound.forest_calm"
            case .oceanWaves:       "sound.ocean_waves"
            case .pianoMeditation:  "sound.piano_meditation"
            case .fluteMeditation:  "sound.flute_meditation"
            }
        }

        var descriptionKey: String {
            switch self {
            case .rainAmbient:      "sound.rain_ambient_desc"
            case .forestCalm:       "sound.forest_calm_desc"
            case .oceanWaves:       "sound.ocean_waves_desc"
            case .pianoMeditation:  "sound.piano_meditation_desc"
            case .fluteMeditation:  "sound.flute_meditation_desc"
            }
        }

        var icon: String {
            switch self {
            case .rainAmbient:      "cloud.rain.fill"
            case .forestCalm:       "leaf.fill"
            case .oceanWaves:       "water.waves"
            case .pianoMeditation:  "pianokeys"
            case .fluteMeditation:  "wand.and.stars"
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

        let savedVol = UserDefaults.standard.double(forKey: Keys.volume)
        self._volume = savedVol > 0 ? savedVol : 0.6

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
        fadeOut(p, duration: 0.3) {
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
        if isPlaying { player?.stop(); player = nil; isPlaying = false }
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
            fadeOut(p, duration: 0.2) {
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
        fadeVolume(p, to: duckedVol, duration: 0.3)
        AudioSessionManager.configureForSpeechOverAmbient()
        Self.log.info("🔉 Ducked ambient to \(duckedVol)")
    }

    /// Вызывается после голосового гида — восстанавливает громкость
    func unduck() {
        guard isPlaying, let p = player else { return }
        AudioSessionManager.configureForAmbient()
        fadeVolume(p, to: Float(volume), duration: 0.5)
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
    private var fadeTask: Task<Void, Never>?

    // MARK: - Fade Helpers

    private func fadeOut(_ player: AVAudioPlayer, duration: Double, completion: @escaping @Sendable () -> Void) {
        let steps = 15
        let interval = duration / Double(steps)
        let startVol = player.volume

        fadeTask?.cancel()
        fadeTask = Task { @MainActor in
            for i in 1...steps {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))
                player.volume = startVol * (1 - Float(i) / Float(steps))
            }
            completion()
        }
    }

    private func fadeVolume(_ player: AVAudioPlayer, to target: Float, duration: Double) {
        let steps = 15
        let interval = duration / Double(steps)
        let startVol = player.volume

        fadeTask?.cancel()
        fadeTask = Task { @MainActor in
            for i in 1...steps {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))
                let progress = Float(i) / Float(steps)
                player.volume = startVol + (target - startVol) * progress
            }
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
