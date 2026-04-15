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
        speak(text, rate: 0.35, pitch: 0.95)
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
        speak(texts[index], rate: 0.36, pitch: 0.92)
    }

    /// Говорит аффирмацию завершения
    func speakCompletion() {
        guard isVoiceEnabled else { return }
        speak(String(localized: "voice.you_did_it"), rate: 0.35, pitch: 0.98)
    }

    /// Говорит "Ты в безопасности"
    func speakSafe() {
        guard isVoiceEnabled else { return }
        speak(String(localized: "voice.you_are_safe"), rate: 0.32, pitch: 0.88)
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

    /// Preferred voice identifier saved by user (nil = auto best)
    var selectedVoiceId: String? {
        get {
            access(keyPath: \.selectedVoiceId)
            return _selectedVoiceId
        }
        set {
            withMutation(keyPath: \.selectedVoiceId) {
                _selectedVoiceId = newValue
                if let id = newValue {
                    UserDefaults.standard.set(id, forKey: "selectedVoiceId")
                } else {
                    UserDefaults.standard.removeObject(forKey: "selectedVoiceId")
                }
            }
        }
    }

    /// Returns ALL voices for the current language, sorted by quality (best first)
    var availableVoices: [AVSpeechSynthesisVoice] {
        let lang = currentLanguageTag
        return AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == lang }
            .sorted { lhs, rhs in
                // Premium > Enhanced > Default
                if lhs.quality != rhs.quality {
                    return lhs.quality.rawValue > rhs.quality.rawValue
                }
                return lhs.name < rhs.name
            }
    }

    /// Human-readable display name for a voice (e.g. "Milena (Улучшенный)")
    func voiceDisplayName(_ voice: AVSpeechSynthesisVoice) -> String {
        let badge: String
        switch voice.quality {
        case .premium:  badge = "★ Premium"
        case .enhanced: badge = "✦ Enhanced"
        default:        badge = "○ Standard"
        }
        return "\(voice.name) — \(badge)"
    }

    /// Checks if a voice is premium or enhanced (not the default compact voice)
    func isHighQualityVoice(_ voice: AVSpeechSynthesisVoice) -> Bool {
        voice.quality.rawValue >= AVSpeechSynthesisVoiceQuality.enhanced.rawValue
    }

    /// Current BCP-47 language tag for voice matching
    private var currentLanguageTag: String {
        let langCode = Locale.current.language.languageCode?.identifier ?? "en"
        return voiceLanguage(for: langCode)
    }

    @ObservationIgnored
    private var _selectedVoiceId: String? = UserDefaults.standard.string(forKey: "selectedVoiceId")

    private func speak(_ text: String, rate: Float = 0.45, pitch: Float = 1.0) {
        // Активируем сессию лениво
        ensureAudioSession()

        // Останавливаем предыдущее
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        // Soft, slow, calming voice — not robotic
        utterance.rate = min(rate, 0.38)            // slower = calmer
        utterance.pitchMultiplier = pitch * 0.92    // slightly lower = warmer
        utterance.volume = 0.85                     // not too loud
        utterance.preUtteranceDelay = 0.2
        utterance.postUtteranceDelay = 0.5

        // Use user-selected voice, or pick the best available
        utterance.voice = resolveVoice()

        synthesizer.speak(utterance)
    }

    /// Resolves the best voice: user selection → premium → enhanced → fallback
    private func resolveVoice() -> AVSpeechSynthesisVoice? {
        let lang = currentLanguageTag

        // 1. User explicitly selected a voice
        if let id = _selectedVoiceId,
           let voice = AVSpeechSynthesisVoice(identifier: id)
        {
            Self.log.info("Using user-selected voice: \(voice.name) [\(voice.quality.rawValue)]")
            return voice
        }

        // 2. Try to find premium voice for current language
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == lang }

        if let premium = allVoices.first(where: { $0.quality == .premium }) {
            Self.log.info("Using premium voice: \(premium.name)")
            return premium
        }

        // 3. Try enhanced voice
        if let enhanced = allVoices.first(where: { $0.quality == .enhanced }) {
            Self.log.info("Using enhanced voice: \(enhanced.name)")
            return enhanced
        }

        // 4. Any voice for exact language match
        if let any = allVoices.first {
            Self.log.info("Using default voice: \(any.name)")
            return any
        }

        // 5. System fallback
        Self.log.warning("No voice found for \(lang), using system fallback")
        return AVSpeechSynthesisVoice(language: lang)
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
