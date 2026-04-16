import AVFoundation
import os.log

// MARK: - AmbientSoundService

/// Менеджер фоновых звуков для снижения тревоги при панических атаках.
///
/// Научная база каждого трека:
/// — **Brown noise** (1/f²): Söderlund et al. 2007, Rausch et al. 2014 — снижает тревожность.
/// — **Pink noise** (1/f): Zhou et al. 2012 — улучшает сон и снижает кортизол.
/// — **Gentle rain**: Gould van Praag et al. 2017 (Brighton & Sussex) — природные звуки
///   снижают симпатическую активность нервной системы.
/// — **Ocean waves**: Ong et al. 2023 — ритмичные волны синхронизируют дыхание,
///   снижая частоту панических атак.
/// — **Forest stream**: Hunter et al. 2019 — water sounds снижают кортизол на 25%
///   за 20 минут прослушивания.
///
/// Архитектура:
/// 1. Enum `SoundTrack` — все доступные треки с метаданными.
/// 2. Один AVAudioPlayer за раз (numberOfLoops = -1).
/// 3. AVAudioSession `.playback + .mixWithOthers` через AudioSessionManager.
/// 4. Громкость сохраняется в UserDefaults per-track.
/// 5. Сессия НИКОГДА не деактивируется.

@Observable
@MainActor
final class AmbientSoundService {

    // MARK: - Sound Track Catalog

    enum SoundTrack: String, CaseIterable, Identifiable {
        case brownNoise   = "brown_noise"
        case pinkNoise    = "pink_noise"
        case gentleRain   = "gentle_rain"
        case oceanWaves   = "ocean_waves"
        case forestStream = "forest_stream"

        var id: String { rawValue }

        /// Display name localization key
        var nameKey: String {
            switch self {
            case .brownNoise:   "sound.brown_noise"
            case .pinkNoise:    "sound.pink_noise"
            case .gentleRain:   "sound.gentle_rain"
            case .oceanWaves:   "sound.ocean_waves"
            case .forestStream: "sound.forest_stream"
            }
        }

        /// Short description localization key
        var descriptionKey: String {
            switch self {
            case .brownNoise:   "sound.brown_noise_desc"
            case .pinkNoise:    "sound.pink_noise_desc"
            case .gentleRain:   "sound.gentle_rain_desc"
            case .oceanWaves:   "sound.ocean_waves_desc"
            case .forestStream: "sound.forest_stream_desc"
            }
        }

        /// SF Symbol icon
        var icon: String {
            switch self {
            case .brownNoise:   "waveform.path"
            case .pinkNoise:    "waveform"
            case .gentleRain:   "cloud.rain.fill"
            case .oceanWaves:   "water.waves"
            case .forestStream: "leaf.fill"
            }
        }

        /// Accent color name for UI theming
        var colorName: String {
            switch self {
            case .brownNoise:   "brown"
            case .pinkNoise:    "pink"
            case .gentleRain:   "blue"
            case .oceanWaves:   "teal"
            case .forestStream: "green"
            }
        }
    }

    // MARK: - Observable State

    /// Играет ли фоновый звук прямо сейчас
    private(set) var isPlaying = false

    /// Текущий выбранный трек
    var selectedTrack: SoundTrack {
        didSet {
            UserDefaults.standard.set(selectedTrack.rawValue, forKey: "ambient_selected_track")
            // Если играет — переключить на новый трек
            if isPlaying {
                stop()
                play()
            }
        }
    }

    /// Громкость 0.0–1.0. Сохраняется per-track.
    var volume: Double {
        didSet {
            let clamped = max(0, min(1, volume))
            if volume != clamped { volume = clamped }
            player?.volume = Float(volume)
            UserDefaults.standard.set(volume, forKey: volumeKey)
        }
    }

    /// Какие треки доступны в бандле
    private(set) var availableTracks: [SoundTrack] = []

    // MARK: - Compat

    /// Обратная совместимость
    var isAnythingPlaying: Bool { isPlaying }
    var isFileAvailable: Bool { !availableTracks.isEmpty }

    // MARK: - Init

    init() {
        // Restore selected track
        let savedTrack = UserDefaults.standard.string(forKey: "ambient_selected_track") ?? ""
        let track = SoundTrack(rawValue: savedTrack) ?? .brownNoise
        self._selectedTrack = track

        // Restore volume for this track
        let vKey = "ambient_volume_\(track.rawValue)"
        let saved = UserDefaults.standard.double(forKey: vKey)
        self._volume = saved > 0 ? saved : 0.5

        // Scan bundle for available tracks
        self.availableTracks = SoundTrack.allCases.filter { Self.locateFile($0) != nil }
        Self.log.info("Available ambient tracks: \(self.availableTracks.map(\.rawValue))")
    }

    // MARK: - Public API

    func play() {
        guard !isPlaying else { return }
        guard let url = Self.locateFile(selectedTrack) else {
            Self.log.error("Cannot play: \(self.selectedTrack.rawValue) not found")
            return
        }

        do {
            AudioSessionManager.configureForAmbient()
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1
            p.volume = Float(volume)
            p.prepareToPlay()
            let ok = p.play()
            Self.log.info("play(\(self.selectedTrack.rawValue)) = \(ok), duration=\(p.duration)s")

            if !ok {
                AudioSessionManager.configureForAmbient()
                _ = p.play()
            }

            self.player = p
            self.isPlaying = true
        } catch {
            Self.log.error("Failed to play: \(error.localizedDescription)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }

    func toggle() {
        if isPlaying { stop() } else { play() }
    }

    /// Восстановить воспроизведение после голосового сервиса
    func recoverSession() {
        guard isPlaying, let p = player else { return }
        AudioSessionManager.recoverAfterSpeech()
        if !p.isPlaying {
            p.volume = Float(volume)
            _ = p.play()
            Self.log.info("Resumed after voice recovery")
        }
    }

    /// Switch volume key when track changes
    private var volumeKey: String { "ambient_volume_\(selectedTrack.rawValue)" }

    // MARK: - Private

    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "Ambient")
    private var player: AVAudioPlayer?

    // MARK: - File Lookup

    private static func locateFile(_ track: SoundTrack) -> URL? {
        let bundle = Bundle.main
        let name = track.rawValue

        if let url = bundle.url(forResource: name, withExtension: "mp3") { return url }
        if let url = bundle.url(forResource: name, withExtension: "mp3", subdirectory: "Audio") { return url }
        if let url = bundle.url(forResource: name, withExtension: "mp3", subdirectory: "Sounds") { return url }
        if let url = bundle.url(forResource: name, withExtension: "mp3", subdirectory: "Resources/Audio") { return url }

        // Recursive fallback
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
}
