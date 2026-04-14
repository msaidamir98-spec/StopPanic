import AVFoundation
import os.log
import SwiftUI

// MARK: - AudioGuideService

// Голосовое сопровождение дыхания и заземления через AVSpeechSynthesizer.
// Работает с выключенным экраном через AVAudioSession.playback.
// Пользователь с закрытыми от страха глазами может следовать только по звуку и вибрации.
//
// Аудио-сессия активируется ЛЕНИВО — только при первом вызове speak(),
// чтобы не захватывать аудиофокус без необходимости (Apple Review).

@Observable
@MainActor
final class AudioGuideService {
    // MARK: Internal

    // MARK: - Breath Voice Phase

    enum BreathVoicePhase {
        case inhale, hold, exhale
    }

    var isVoiceEnabled: Bool {
        get {
            access(keyPath: \.isVoiceEnabled)
            return _isVoiceEnabled
        }
        set {
            withMutation(keyPath: \.isVoiceEnabled) {
                _isVoiceEnabled = newValue
                UserDefaults.standard.set(newValue, forKey: "voiceGuideEnabled")
                // Деактивируем сессию если голос выключен
                if !newValue {
                    deactivateAudioSession()
                }
            }
        }
    }

    /// Говорит фазу дыхания: "Вдох", "Задержка", "Выдох"
    func speakBreathPhase(_ phase: BreathVoicePhase) {
        guard isVoiceEnabled else { return }
        let text = switch phase {
        case .inhale:
            String(localized: "voice.inhale")
        case .hold:
            String(localized: "voice.hold")
        case .exhale:
            String(localized: "voice.exhale")
        }
        speak(text, rate: 0.4, pitch: 1.0)
    }

    /// Говорит шаг заземления: "Назови 5 вещей которые ты видишь"
    func speakGroundingStep(_ step: Int) {
        guard isVoiceEnabled else { return }
        let texts = [
            String(localized: "voice.ground_see"),
            String(localized: "voice.ground_touch"),
            String(localized: "voice.ground_hear"),
            String(localized: "voice.ground_smell"),
            String(localized: "voice.ground_taste"),
        ]
        let index = min(step, texts.count - 1)
        speak(texts[index], rate: 0.42, pitch: 0.95)
    }

    /// Говорит аффирмацию завершения
    func speakCompletion() {
        guard isVoiceEnabled else { return }
        speak(String(localized: "voice.you_did_it"), rate: 0.4, pitch: 1.05)
    }

    /// Говорит "Ты в безопасности"
    func speakSafe() {
        guard isVoiceEnabled else { return }
        speak(String(localized: "voice.you_are_safe"), rate: 0.38, pitch: 0.9)
    }

    /// Останавливает текущую речь и деактивирует аудио-сессию
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        deactivateAudioSession()
    }

    // MARK: Private

    nonisolated(unsafe) private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "AudioGuide")

    /// Включено ли голосовое сопровождение (UserDefaults)
    @ObservationIgnored
    private var _isVoiceEnabled: Bool = UserDefaults.standard.object(forKey: "voiceGuideEnabled") != nil
        ? UserDefaults.standard.bool(forKey: "voiceGuideEnabled")
        : true // по умолчанию включено

    nonisolated(unsafe) private let synthesizer = AVSpeechSynthesizer()

    /// Флаг — сессия уже активирована
    private var isSessionActive = false

    /// Активируем AVAudioSession лениво — только когда реально нужен звук
    private func ensureAudioSession() {
        guard !isSessionActive else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
            isSessionActive = true
        } catch {
            Self.log.error("Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    /// Деактивируем аудио-сессию — возвращаем фокус другим приложениям
    private func deactivateAudioSession() {
        guard isSessionActive else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(false, options: .notifyOthersOnDeactivation)
            isSessionActive = false
        } catch {
            Self.log.error("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }

    private func speak(_ text: String, rate: Float = 0.45, pitch: Float = 1.0) {
        // Активируем сессию лениво
        ensureAudioSession()

        // Останавливаем предыдущее
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = 0.9
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.3

        // Определяем язык из текущей локали
        let langCode = Locale.current.language.languageCode?.identifier ?? "en"
        utterance.voice = AVSpeechSynthesisVoice(language: voiceLanguage(for: langCode))

        synthesizer.speak(utterance)
    }

    private func voiceLanguage(for code: String) -> String {
        switch code {
        case "ru": "ru-RU"
        case "de": "de-DE"
        case "es": "es-ES"
        case "fr": "fr-FR"
        case "ja": "ja-JP"
        case "pt": "pt-BR"
        case "zh": "zh-CN"
        default: "en-US"
        }
    }
}
