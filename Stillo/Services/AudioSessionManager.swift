import AVFoundation
import os.log

// MARK: - AudioSessionManager

/// Единая точка конфигурации AVAudioSession.
/// Все сервисы (AmbientSound, AudioGuide, VoiceBank, OpenAITTS) вызывают
/// эти методы вместо прямого обращения к AVAudioSession.sharedInstance().
@MainActor
enum AudioSessionManager {
    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "AudioSession")

    /// Для фонового звука (ambient brown noise): .playback + .mixWithOthers
    static func configureForAmbient() {
        configure(mode: .default, options: [.mixWithOthers])
    }

    /// Для голоса (TTS / VoiceBank / AVSpeech): .playback + .duckOthers
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
