import AVFoundation
import os.log
import SwiftUI

// MARK: - AudioGuideService

/// Голосовое сопровождение дыхания и заземления через AVSpeechSynthesizer.
/// Работает с выключенным экраном через AVAudioSession.playback.
/// Пользователь с закрытыми от страха глазами может следовать только по звуку и вибрации.

@Observable
@MainActor
final class AudioGuideService {
    // MARK: Lifecycle

    init() {
        configureAudioSession()
    }

    // MARK: Internal

    /// Включено ли голосовое сопровождение (UserDefaults)
    @ObservationIgnored
    private var _isVoiceEnabled: Bool = UserDefaults.standard.object(forKey: "voiceGuideEnabled") != nil
        ? UserDefaults.standard.bool(forKey: "voiceGuideEnabled")
        : true // по умолчанию включено

    var isVoiceEnabled: Bool {
        get {
            access(keyPath: \.isVoiceEnabled)
            return _isVoiceEnabled
        }
        set {
            withMutation(keyPath: \.isVoiceEnabled) {
                _isVoiceEnabled = newValue
                UserDefaults.standard.set(newValue, forKey: "voiceGuideEnabled")
            }
        }
    }

    /// Говорит фазу дыхания: "Вдох", "Задержка", "Выдох"
    func speakBreathPhase(_ phase: BreathVoicePhase) {
        guard isVoiceEnabled else { return }
        let text: String
        switch phase {
        case .inhale:
            text = String(localized: "voice.inhale")
        case .hold:
            text = String(localized: "voice.hold")
        case .exhale:
            text = String(localized: "voice.exhale")
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

    /// Останавливает текущую речь
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: - Breath Voice Phase

    enum BreathVoicePhase {
        case inhale, hold, exhale
    }

    // MARK: Private

    nonisolated(unsafe) private let synthesizer = AVSpeechSynthesizer()
    nonisolated(unsafe) private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "AudioGuide")

    /// Настраиваем AVAudioSession для работы с выключенным экраном
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            Self.log.error("Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    private func speak(_ text: String, rate: Float = 0.45, pitch: Float = 1.0) {
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
