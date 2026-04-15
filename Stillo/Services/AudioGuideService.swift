import AVFoundation
import os.log
import SwiftUI

// MARK: - AudioGuideService

/// Голосовое сопровождение дыхательных упражнений и заземления.
///
/// Трёхуровневая система голоса:
///   1. 🥇 VoiceBankService — предзаписанные MP3 из бандла (мгновенно, оффлайн)
///   2. 🥈 OpenAITTSService — через API OpenAI (если пользователь ввёл ключ)
///   3. 🥉 AVSpeechSynthesizer — системный голос iOS (всегда доступен)
///
/// Аудио-сессия активируется лениво — только при speak(), не захватывает фокус
/// без необходимости (Apple Review friendly).

@Observable
@MainActor
final class AudioGuideService {
    // MARK: - Breath Phase

    enum BreathVoicePhase {
        case inhale, hold, exhale
    }

    // MARK: - Dependencies (injected by AppCoordinator)

    /// Предзаписанные фразы — основной источник
    var voiceBank: VoiceBankService?

    /// OpenAI TTS — опциональный премиум-голос
    var ttsService: OpenAITTSService?

    // MARK: - State

    var isVoiceEnabled: Bool {
        get {
            access(keyPath: \.isVoiceEnabled)
            return _isVoiceEnabled
        }
        set {
            withMutation(keyPath: \.isVoiceEnabled) {
                _isVoiceEnabled = newValue
                UserDefaults.standard.set(newValue, forKey: "voiceGuideEnabled")
                if !newValue {
                    stop()
                }
            }
        }
    }

    /// Какой источник голоса сейчас используется
    enum VoiceSource: String {
        case voiceBank = "Pre-recorded"
        case openAI = "OpenAI TTS"
        case system = "System Voice"
    }

    /// Текущий активный источник (для отображения в UI)
    var activeSource: VoiceSource {
        if let vb = voiceBank, vb.isEnabled, vb.availablePhraseCount > 0 {
            return .voiceBank
        }
        if let tts = ttsService, tts.isReady {
            return .openAI
        }
        return .system
    }

    // MARK: - Public API: Breathing

    func speakBreathPhase(_ phase: BreathVoicePhase) {
        guard isVoiceEnabled else { return }
        let phrase: VoiceBankService.Phrase
        let text: String
        switch phase {
        case .inhale:
            phrase = .breatheIn
            text = String(localized: "voice.inhale")
        case .hold:
            phrase = .hold
            text = String(localized: "voice.hold")
        case .exhale:
            phrase = .breatheOut
            text = String(localized: "voice.exhale")
        }
        smartSpeak(phrase: phrase, fallbackText: text, rate: 0.35, pitch: 0.95)
    }

    // MARK: - Public API: Grounding 5-4-3-2-1

    func speakGroundingStep(_ step: Int) {
        guard isVoiceEnabled else { return }
        let phrases: [VoiceBankService.Phrase] = [
            .groundSee, .groundTouch, .groundHear, .groundSmell, .groundTaste
        ]
        let texts = [
            String(localized: "voice.ground_see"),
            String(localized: "voice.ground_touch"),
            String(localized: "voice.ground_hear"),
            String(localized: "voice.ground_smell"),
            String(localized: "voice.ground_taste"),
        ]
        let index = min(step, phrases.count - 1)
        smartSpeak(phrase: phrases[index], fallbackText: texts[index], rate: 0.36, pitch: 0.92)
    }

    // MARK: - Public API: Completion & Safety

    func speakCompletion() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .youDidIt, fallbackText: String(localized: "voice.you_did_it"), rate: 0.35, pitch: 0.98)
    }

    func speakSafe() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .youAreSafe, fallbackText: String(localized: "voice.you_are_safe"), rate: 0.32, pitch: 0.88)
    }

    // MARK: - Public API: Session & SOS

    func speakWelcome() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .welcome, fallbackText: String(localized: "voice.inhale"), rate: 0.34, pitch: 0.9)
    }

    func speakSessionStart() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .sessionStart, fallbackText: "", rate: 0.34, pitch: 0.9)
    }

    func speakPanicIntro() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .panicIntro, fallbackText: String(localized: "voice.you_are_safe"), rate: 0.30, pitch: 0.85)
    }

    func speakSOSCalm() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .sosCalmDown, fallbackText: String(localized: "voice.you_are_safe"), rate: 0.30, pitch: 0.85)
    }

    func speakEncouragement() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .greatJob, fallbackText: "", rate: 0.34, pitch: 0.92)
    }

    func speakAlmostDone() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .almostDone, fallbackText: "", rate: 0.34, pitch: 0.9)
    }

    func speakRelaxShoulders() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .relaxShoulders, fallbackText: "", rate: 0.32, pitch: 0.88)
    }

    func speakCloseEyes() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .closeEyes, fallbackText: "", rate: 0.32, pitch: 0.88)
    }

    func speakFocusBreath() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .focusBreath, fallbackText: "", rate: 0.32, pitch: 0.88)
    }

    /// Останавливает всё воспроизведение
    func stop() {
        voiceBank?.stop()
        ttsService?.stop()
        synthesizer.stopSpeaking(at: .immediate)
        deactivateAudioSession()
    }

    // MARK: - Voice Selection (for AVSpeech fallback)

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

    var availableVoices: [AVSpeechSynthesisVoice] {
        let lang = currentLanguageTag
        return AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == lang }
            .sorted { lhs, rhs in
                if lhs.quality != rhs.quality {
                    return lhs.quality.rawValue > rhs.quality.rawValue
                }
                return lhs.name < rhs.name
            }
    }

    func voiceDisplayName(_ voice: AVSpeechSynthesisVoice) -> String {
        let badge: String
        switch voice.quality {
        case .premium:  badge = "★ Premium"
        case .enhanced: badge = "✦ Enhanced"
        default:        badge = "○ Standard"
        }
        return "\(voice.name) — \(badge)"
    }

    func isHighQualityVoice(_ voice: AVSpeechSynthesisVoice) -> Bool {
        voice.quality.rawValue >= AVSpeechSynthesisVoiceQuality.enhanced.rawValue
    }

    // MARK: - Private

    nonisolated(unsafe) private static let log = Logger(
        subsystem: "MSK-PRODUKT.StopPanic",
        category: "AudioGuide"
    )

    @ObservationIgnored
    private var _isVoiceEnabled: Bool = {
        if UserDefaults.standard.object(forKey: "voiceGuideEnabled") != nil {
            return UserDefaults.standard.bool(forKey: "voiceGuideEnabled")
        }
        return true
    }()

    @ObservationIgnored
    private var _selectedVoiceId: String? = UserDefaults.standard.string(forKey: "selectedVoiceId")

    nonisolated(unsafe) private let synthesizer = AVSpeechSynthesizer()

    private var isSessionActive = false

    // MARK: - Smart Speak (Three-tier cascade)

    private func smartSpeak(
        phrase: VoiceBankService.Phrase,
        fallbackText: String,
        rate: Float = 0.45,
        pitch: Float = 1.0
    ) {
        // 🥇 Tier 1: Pre-recorded voice bank (instant, offline)
        if let vb = voiceBank, vb.play(phrase) {
            Self.log.info("Played from VoiceBank: \(phrase.rawValue)")
            return
        }

        // 🥈 Tier 2: OpenAI TTS (premium, requires API key + internet)
        if let tts = ttsService, tts.isReady, !fallbackText.isEmpty {
            Self.log.info("Playing via OpenAI TTS: \(phrase.rawValue)")
            tts.speak(fallbackText, speed: Double(rate) * 2.5)
            return
        }

        // 🥉 Tier 3: System voice (always available)
        if !fallbackText.isEmpty {
            Self.log.info("Falling back to AVSpeech: \(phrase.rawValue)")
            speakLocal(fallbackText, rate: rate, pitch: pitch)
        }
    }

    // MARK: - AVSpeech Fallback

    private func speakLocal(_ text: String, rate: Float = 0.45, pitch: Float = 1.0) {
        ensureAudioSession()

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = min(rate, 0.38)
        utterance.pitchMultiplier = pitch * 0.92
        utterance.volume = 0.85
        utterance.preUtteranceDelay = 0.2
        utterance.postUtteranceDelay = 0.5
        utterance.voice = resolveVoice()

        synthesizer.speak(utterance)
    }

    private func resolveVoice() -> AVSpeechSynthesisVoice? {
        let lang = currentLanguageTag

        if let id = _selectedVoiceId,
           let voice = AVSpeechSynthesisVoice(identifier: id)
        {
            return voice
        }

        let allVoices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == lang }

        if let premium = allVoices.first(where: { $0.quality == .premium }) {
            return premium
        }
        if let enhanced = allVoices.first(where: { $0.quality == .enhanced }) {
            return enhanced
        }
        return allVoices.first ?? AVSpeechSynthesisVoice(language: lang)
    }

    // MARK: - Audio Session

    private func ensureAudioSession() {
        guard !isSessionActive else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
            isSessionActive = true
        } catch {
            Self.log.error("Audio session error: \(error.localizedDescription)")
        }
    }

    private func deactivateAudioSession() {
        guard isSessionActive else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
            isSessionActive = false
        } catch {
            Self.log.error("Session deactivation error: \(error.localizedDescription)")
        }
    }

    // MARK: - Language Mapping

    private var currentLanguageTag: String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return voiceLanguage(for: code)
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
