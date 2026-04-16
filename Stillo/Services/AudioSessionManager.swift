import AVFoundation
import os.log

// MARK: - AudioSessionManager

/// Единая точка конфигурации AVAudioSession.
///
/// Режимы:
/// 1. Ambient — фоновый звук (дождь/пианино) играет один: .playback + .mixWithOthers
/// 2. SpeechOverAmbient — голос гида поверх фона: .playback + .duckOthers
///    (iOS автоматически приглушает ambient, а мы дополнительно duck через AmbientSoundService)
/// 3. Speech — только голос, без фона: .playback + .spokenAudio + .duckOthers
@MainActor
enum AudioSessionManager {
    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "AudioSession")

    /// Для фонового звука (ambient loops): .playback + .mixWithOthers
    static func configureForAmbient() {
        configure(mode: .default, options: [.mixWithOthers])
    }

    /// Для голоса ПОВЕРХ фона: дождь приглушается, голос слышен чётко
    static func configureForSpeechOverAmbient() {
        configure(mode: .spokenAudio, options: [.mixWithOthers, .duckOthers])
    }

    /// Для голоса без фона (TTS / VoiceBank / AVSpeech)
    static func configureForSpeech() {
        configure(mode: .spokenAudio, options: [.duckOthers])
    }

    /// Восстановить ambient-сессию после голоса
    static func recoverAfterSpeech() {
        configureForAmbient()
    }

    // MARK: - Private

    private static func configure(
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: mode, options: options)
            try session.setActive(true)
        } catch {
            log.error("AudioSession configure failed: \(error.localizedDescription)")
        }
    }
}
