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
///
/// **Активация сессии**: setActive(true) вызывается ровно один раз — при
/// первой настройке. Повторная активация на каждом голосовом фрагменте
/// создаёт гонку с уже играющим ambient-плеером (50–200 мс заиканий
/// в SOS-флоу). Деактивация — только через `teardown()` при app
/// terminate; в обычной жизни iOS сам управляет жизненным циклом сессии.
@MainActor
enum AudioSessionManager {
    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "AudioSession")

    /// Активна ли уже AVAudioSession. Защищает от повторного setActive(true)
    /// в горячих путях SOS-флоу (VoiceBank → AmbientSound → AudioGuide).
    private static var isActivated = false

    /// Для фонового звука (ambient loops): .playback + .mixWithOthers
    static func configureForAmbient() {
        configure(mode: .default, options: [.mixWithOthers])
    }

    /// Для голоса ПОВЕРХ фона: дождь приглушается, голос слышен чётко
    static func configureForSpeechOverAmbient() {
        configure(mode: .spokenAudio, options: [.mixWithOthers, .duckOthers])
    }

    /// Для голоса без фона (TTS / VoiceBank / AVSpeech).
    /// `.mixWithOthers` обязателен: без него активация сессии на VoiceBank-плеере
    /// снимает наш собственный ambient-плеер с воспроизведения.
    static func configureForSpeech() {
        configure(mode: .spokenAudio, options: [.mixWithOthers, .duckOthers])
    }

    /// Восстановить ambient-сессию после голоса
    static func recoverAfterSpeech() {
        configureForAmbient()
    }

    /// Полностью отключить сессию. Вызывается из AudioController.silenceAll
    /// при переходе в .background.
    static func teardown() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
            isActivated = false
        } catch {
            log.error("AudioSession teardown failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Private

    private static func configure(
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: mode, options: options)
            // Активируем сессию ровно один раз. Повторный setActive(true)
            // на каждом фрагменте голоса роняет уже играющий ambient.
            if !isActivated {
                try session.setActive(true)
                isActivated = true
            }
        } catch {
            log.error("AudioSession configure failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
