import AVFoundation
import Combine
import os.log
import SwiftUI

// MARK: - AmbientSoundService

/// Аудио-менеджер для фоновой музыки и звуков природы.
/// Поддерживает микширование нескольких слоёв: музыка + дождь + лес и т.д.
/// Все треки зацикливаются бесшовно.
///
/// Архитектура:
/// - Каждый трек — отдельный AVAudioPlayer с независимой громкостью
/// - Плавные fade-in/fade-out при включении/выключении (0.8s)
/// - Аудио-сессия .playback + .mixWithOthers — не глушит голос/OpenAI TTS
/// - НИКОГДА не вызывает setActive(false) — сессия живёт пока приложение активно
/// - Другие сервисы (VoiceBankService, AudioGuideService) НЕ деактивируют
///   общую сессию, а только переключают категорию; ambient продолжает играть.

@Observable
@MainActor
final class AmbientSoundService {
    // MARK: - Sound Categories

    /// Фоновая музыка (играет одна из выбранных)
    enum MusicTrack: String, CaseIterable, Identifiable {
        case calmPiano   = "calm_piano"
        case softAmbient = "soft_ambient"
        case gentleGuitar = "gentle_guitar"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .calmPiano:    String(localized: "ambient.music_piano")
            case .softAmbient:  String(localized: "ambient.music_ambient")
            case .gentleGuitar: String(localized: "ambient.music_guitar")
            }
        }

        var emoji: String {
            switch self {
            case .calmPiano: "🎹"
            case .softAmbient: "🎵"
            case .gentleGuitar: "🎸"
            }
        }

        var fileName: String { rawValue }
    }

    /// Звуки природы (могут играть одновременно с музыкой)
    enum NatureSound: String, CaseIterable, Identifiable {
        case rain       = "rain"
        case forest     = "forest"
        case ocean      = "ocean"
        case fireplace  = "fireplace"
        case nightBirds = "night_birds"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .rain:       String(localized: "ambient.nature_rain")
            case .forest:     String(localized: "ambient.nature_forest")
            case .ocean:      String(localized: "ambient.nature_ocean")
            case .fireplace:  String(localized: "ambient.nature_fireplace")
            case .nightBirds: String(localized: "ambient.nature_birds")
            }
        }

        var emoji: String {
            switch self {
            case .rain: "🌧️"
            case .forest: "🌲"
            case .ocean: "🌊"
            case .fireplace: "🔥"
            case .nightBirds: "🦉"
            }
        }

        var fileName: String { rawValue }
    }

    // MARK: - Observable State

    /// Is background music playing?
    var isMusicPlaying: Bool {
        get {
            access(keyPath: \.isMusicPlaying)
            return _isMusicPlaying
        }
        set {
            withMutation(keyPath: \.isMusicPlaying) {
                _isMusicPlaying = newValue
                UserDefaults.standard.set(newValue, forKey: "ambient_music_playing")
            }
        }
    }

    /// Currently selected music track
    var selectedMusic: MusicTrack? {
        get {
            access(keyPath: \.selectedMusic)
            return _selectedMusic
        }
        set {
            withMutation(keyPath: \.selectedMusic) {
                _selectedMusic = newValue
                if let track = newValue {
                    UserDefaults.standard.set(track.rawValue, forKey: "ambient_selected_music")
                } else {
                    UserDefaults.standard.removeObject(forKey: "ambient_selected_music")
                }
            }
        }
    }

    /// Music volume 0.0–1.0
    var musicVolume: Float {
        get {
            access(keyPath: \.musicVolume)
            return _musicVolume
        }
        set {
            withMutation(keyPath: \.musicVolume) {
                _musicVolume = newValue
                UserDefaults.standard.set(newValue, forKey: "ambient_music_volume")
                musicPlayer?.volume = newValue * _masterVolume
            }
        }
    }

    /// Active nature sounds with their volumes
    var activeNatureSounds: Set<NatureSound> {
        get {
            access(keyPath: \.activeNatureSounds)
            return _activeNatureSounds
        }
        set {
            withMutation(keyPath: \.activeNatureSounds) {
                _activeNatureSounds = newValue
                let raw = newValue.map(\.rawValue)
                UserDefaults.standard.set(raw, forKey: "ambient_active_nature")
            }
        }
    }

    /// Per-sound volume
    var natureVolumes: [NatureSound: Float] {
        get {
            access(keyPath: \.natureVolumes)
            return _natureVolumes
        }
        set {
            withMutation(keyPath: \.natureVolumes) {
                _natureVolumes = newValue
                let raw = Dictionary(uniqueKeysWithValues: newValue.map { ($0.key.rawValue, $0.value) })
                UserDefaults.standard.set(raw, forKey: "ambient_nature_volumes")
            }
        }
    }

    /// Master volume 0.0–1.0
    var masterVolume: Float {
        get {
            access(keyPath: \.masterVolume)
            return _masterVolume
        }
        set {
            withMutation(keyPath: \.masterVolume) {
                _masterVolume = newValue
                UserDefaults.standard.set(newValue, forKey: "ambient_master_volume")
                applyMasterVolume()
            }
        }
    }

    /// Is anything playing at all?
    var isAnythingPlaying: Bool {
        isMusicPlaying || !activeNatureSounds.isEmpty
    }

    // MARK: - Public API

    /// Play selected music track
    func playMusic() {
        guard let track = selectedMusic else {
            Self.log.warning("playMusic called but no track selected")
            return
        }
        stopMusic(fade: false)

        guard let url = Self.audioURL(for: track.fileName) else {
            Self.log.error("Music file not found: \(track.fileName).mp3 — checking bundle contents")
            Self.debugBundleAudio()
            isMusicPlaying = false
            return
        }

        do {
            activateSession()
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1 // infinite loop
            p.volume = 0
            p.prepareToPlay()
            let started = p.play()
            Self.log.info("Music play started=\(started) file=\(url.lastPathComponent) duration=\(p.duration)")
            if !started {
                // Retry: re-activate session and try once more
                Self.log.warning("Music play returned false, retrying…")
                activateSession(force: true)
                p.play()
            }
            p.setVolume(musicVolume * masterVolume, fadeDuration: fadeDuration)
            musicPlayer = p
            isMusicPlaying = true
        } catch {
            Self.log.error("Failed to play music: \(error.localizedDescription)")
        }
    }

    /// Stop music with fade-out
    func stopMusic(fade: Bool = true) {
        if fade, let p = musicPlayer, p.isPlaying {
            p.setVolume(0, fadeDuration: fadeDuration)
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) { [weak p] in
                p?.stop()
            }
        } else {
            musicPlayer?.stop()
        }
        musicPlayer = nil
        isMusicPlaying = false
    }

    /// Toggle a nature sound on/off
    func toggleNatureSound(_ sound: NatureSound) {
        if activeNatureSounds.contains(sound) {
            stopNatureSound(sound)
        } else {
            playNatureSound(sound)
        }
    }

    /// Play a nature sound
    func playNatureSound(_ sound: NatureSound) {
        // Stop existing player for this sound if any
        naturePlayers[sound]?.stop()
        naturePlayers.removeValue(forKey: sound)

        guard let url = Self.audioURL(for: sound.fileName) else {
            Self.log.error("Nature sound not found: \(sound.fileName).mp3")
            Self.debugBundleAudio()
            return
        }

        do {
            activateSession()
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1
            p.volume = 0
            p.prepareToPlay()
            let started = p.play()
            let vol = (natureVolumes[sound] ?? 0.5) * masterVolume
            Self.log.info("Nature play started=\(started) file=\(url.lastPathComponent) vol=\(vol)")
            if !started {
                Self.log.warning("Nature play returned false, retrying…")
                activateSession(force: true)
                p.play()
            }
            p.setVolume(vol, fadeDuration: fadeDuration)
            naturePlayers[sound] = p
            activeNatureSounds.insert(sound)
        } catch {
            Self.log.error("Failed to play nature sound: \(error.localizedDescription)")
        }
    }

    /// Stop a nature sound with fade-out
    func stopNatureSound(_ sound: NatureSound, fade: Bool = true) {
        if fade, let p = naturePlayers[sound], p.isPlaying {
            p.setVolume(0, fadeDuration: fadeDuration)
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) { [weak p] in
                p?.stop()
            }
        } else {
            naturePlayers[sound]?.stop()
        }
        naturePlayers.removeValue(forKey: sound)
        activeNatureSounds.remove(sound)
    }

    /// Update volume for a specific nature sound
    func setNatureVolume(_ sound: NatureSound, volume: Float) {
        var vols = natureVolumes
        vols[sound] = volume
        natureVolumes = vols
        naturePlayers[sound]?.setVolume(volume * masterVolume, fadeDuration: 0.2)
    }

    /// Stop everything
    func stopAll() {
        stopMusic()
        for sound in activeNatureSounds {
            stopNatureSound(sound)
        }
    }

    /// Восстанавливает сессию после того, как VoiceBankService/AudioGuide
    /// переключили категорию на .spokenAudio + .duckOthers.
    /// Вызывается из VoiceBankService.deactivateSession() и AudioGuideService.
    func recoverSession() {
        guard isAnythingPlaying else { return }
        Self.log.info("Recovering ambient session after voice playback ended")
        activateSession(force: true)
        // Resume players that may have been interrupted
        if let mp = musicPlayer, !mp.isPlaying, isMusicPlaying {
            mp.play()
            mp.setVolume(musicVolume * masterVolume, fadeDuration: 0.3)
        }
        for (sound, player) in naturePlayers {
            if !player.isPlaying {
                player.play()
                let vol = (natureVolumes[sound] ?? 0.5) * masterVolume
                player.setVolume(vol, fadeDuration: 0.3)
            }
        }
    }

    // MARK: - Private

    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "AmbientSound")

    private let fadeDuration: TimeInterval = 0.8

    @ObservationIgnored
    private var _isMusicPlaying: Bool = UserDefaults.standard.bool(forKey: "ambient_music_playing")

    @ObservationIgnored
    private var _selectedMusic: MusicTrack? = {
        guard let raw = UserDefaults.standard.string(forKey: "ambient_selected_music") else { return .calmPiano }
        return MusicTrack(rawValue: raw) ?? .calmPiano
    }()

    @ObservationIgnored
    private var _musicVolume: Float = {
        let v = UserDefaults.standard.float(forKey: "ambient_music_volume")
        return v > 0 ? v : 0.3
    }()

    @ObservationIgnored
    private var _activeNatureSounds: Set<NatureSound> = {
        guard let raw = UserDefaults.standard.stringArray(forKey: "ambient_active_nature") else { return [] }
        return Set(raw.compactMap { NatureSound(rawValue: $0) })
    }()

    @ObservationIgnored
    private var _natureVolumes: [NatureSound: Float] = {
        guard let raw = UserDefaults.standard.dictionary(forKey: "ambient_nature_volumes") as? [String: Float] else { return [:] }
        return Dictionary(uniqueKeysWithValues: raw.compactMap { key, val in
            NatureSound(rawValue: key).map { ($0, val) }
        })
    }()

    @ObservationIgnored
    private var _masterVolume: Float = {
        let v = UserDefaults.standard.float(forKey: "ambient_master_volume")
        return v > 0 ? v : 0.7
    }()

    @ObservationIgnored
    private var musicPlayer: AVAudioPlayer?

    @ObservationIgnored
    private var naturePlayers: [NatureSound: AVAudioPlayer] = [:]

    /// Find audio file in bundle — checks subdirectories too
    static func audioURL(for name: String) -> URL? {
        // Try direct bundle lookup
        if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
            return url
        }
        // Try Resources/Audio subdirectory
        if let url = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Audio") {
            return url
        }
        // Search recursively
        if let resourcePath = Bundle.main.resourcePath {
            let fm = FileManager.default
            if let enumerator = fm.enumerator(atPath: resourcePath) {
                while let file = enumerator.nextObject() as? String {
                    if file.hasSuffix("/\(name).mp3") || file == "\(name).mp3" {
                        return URL(fileURLWithPath: resourcePath).appendingPathComponent(file)
                    }
                }
            }
        }
        return nil
    }

    /// Активирует аудиосессию для фоновых звуков.
    /// force=true — всегда переконфигурирует (после чужого setCategory).
    /// НИКОГДА не вызывает setActive(false) — звуки не должны прерываться.
    private func activateSession(force: Bool = false) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            Self.log.info("Audio session activated for ambient sounds (force=\(force))")
        } catch {
            Self.log.error("Audio session error: \(error.localizedDescription)")
        }
    }

    private func applyMasterVolume() {
        musicPlayer?.volume = musicVolume * masterVolume
        for (sound, player) in naturePlayers {
            let vol = (natureVolumes[sound] ?? 0.5) * masterVolume
            player.volume = vol
        }
    }

    /// Debug: list all mp3 files found in bundle
    static func debugBundleAudio() {
        guard let resourcePath = Bundle.main.resourcePath else {
            log.error("No bundle resourcePath")
            return
        }
        let fm = FileManager.default
        var mp3Files: [String] = []
        if let enumerator = fm.enumerator(atPath: resourcePath) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix(".mp3") {
                    mp3Files.append(file)
                }
            }
        }
        log.info("Bundle MP3 files (\(mp3Files.count)): \(mp3Files.joined(separator: ", "))")
    }
}
