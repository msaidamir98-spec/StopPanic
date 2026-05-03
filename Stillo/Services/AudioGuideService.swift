import AVFoundation
import os.log
import SwiftUI

// MARK: - AudioGuideService

/// Голосовое сопровождение дыхательных упражнений и заземления.
///
/// Двухуровневая система голоса (100% оффлайн):
///   1. 🥇 VoiceBankService — предзаписанные MP3 из бандла (мгновенно, оффлайн)
///   2. 🥈 AVSpeechSynthesizer — системный голос iOS (всегда доступен)
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

    /// Ссылка на ambient — для восстановления сессии после голоса
    var ambientSound: AmbientSoundService?

    // MARK: - State

    var isVoiceEnabled: Bool {
        get {
            access(keyPath: \.isVoiceEnabled)
            return _isVoiceEnabled
        }
        set {
            withMutation(keyPath: \.isVoiceEnabled) {
                _isVoiceEnabled = newValue
                UserDefaults.standard.set(newValue, forKey: "audioGuideEnabled")
                if !newValue {
                    stop()
                }
            }
        }
    }

    /// Какой источник голоса сейчас используется
    enum VoiceSource: String, CaseIterable {
        case voiceBank = "Pre-recorded"
        case system = "System Voice"
    }

    /// Режим голоса, выбранный пользователем
    /// .voiceBank = предзаписанные (по умолчанию)
    /// .system = системный AVSpeech (выбор голоса работает)
    var preferredSource: VoiceSource {
        get {
            access(keyPath: \.preferredSource)
            return _preferredSource
        }
        set {
            withMutation(keyPath: \.preferredSource) {
                _preferredSource = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: "preferredVoiceSource")
            }
        }
    }

    /// Текущий активный источник (для отображения в UI)
    var activeSource: VoiceSource {
        switch _preferredSource {
        case .voiceBank:
            if let vb = voiceBank, vb.isEnabled, vb.availablePhraseCount > 0 {
                return .voiceBank
            }
            return .system
        case .system:
            return .system
        }
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
        smartSpeak(phrase: phrase, fallbackText: text, rate: 0.5, pitch: 1.0)
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
        smartSpeak(phrase: phrases[index], fallbackText: texts[index], rate: 0.5, pitch: 1.0)
    }

    // MARK: - Public API: Completion & Safety

    func speakCompletion() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .youDidIt, fallbackText: String(localized: "voice.you_did_it"), rate: 0.5, pitch: 1.05)
    }

    func speakSafe() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .youAreSafe, fallbackText: String(localized: "voice.you_are_safe"), rate: 0.48, pitch: 0.95)
    }

    // MARK: - Public API: Session & SOS

    func speakWelcome() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .welcome, fallbackText: String(localized: "voice.inhale"), rate: 0.5, pitch: 1.0)
    }

    func speakSessionStart() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .sessionStart, fallbackText: "", rate: 0.5, pitch: 1.0)
    }

    func speakPanicIntro() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .panicIntro, fallbackText: String(localized: "voice.you_are_safe"), rate: 0.48, pitch: 0.95)
    }

    func speakSOSCalm() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .sosCalmDown, fallbackText: String(localized: "voice.you_are_safe"), rate: 0.48, pitch: 0.95)
    }

    func speakEncouragement() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .greatJob, fallbackText: "", rate: 0.5, pitch: 1.0)
    }

    func speakAlmostDone() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .almostDone, fallbackText: "", rate: 0.5, pitch: 1.0)
    }

    func speakRelaxShoulders() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .relaxShoulders, fallbackText: "", rate: 0.48, pitch: 0.95)
    }

    func speakCloseEyes() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .closeEyes, fallbackText: "", rate: 0.48, pitch: 0.95)
    }

    func speakFocusBreath() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .focusBreath, fallbackText: "", rate: 0.48, pitch: 0.95)
    }

    // MARK: - CBT & Grounding (new medically-grounded phrases)

    func speakBodyRelax() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .bodyRelax, fallbackText: String(localized: "voice.body_relax"), rate: 0.48, pitch: 0.95)
    }

    func speakFeetOnFloor() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .feetOnFloor, fallbackText: String(localized: "voice.feet_on_floor"), rate: 0.5, pitch: 1.0)
    }

    func speakSafePlace() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .safePlace, fallbackText: String(localized: "voice.safe_place"), rate: 0.48, pitch: 0.95)
    }

    func speakNotInDanger() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .notInDanger, fallbackText: String(localized: "voice.not_in_danger"), rate: 0.48, pitch: 0.95)
    }

    func speakThisWillPass() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .thisWillPass, fallbackText: String(localized: "voice.this_will_pass"), rate: 0.48, pitch: 0.95)
    }

    func speakSlowDown() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .slowDown, fallbackText: String(localized: "voice.slow_down"), rate: 0.45, pitch: 0.9)
    }

    func speakNameObjects() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .nameObjects, fallbackText: String(localized: "voice.name_objects"), rate: 0.5, pitch: 1.0)
    }

    func speakColdWater() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .coldWater, fallbackText: String(localized: "voice.cold_water"), rate: 0.5, pitch: 1.0)
    }

    func speakTenseFists() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .tenseFists, fallbackText: String(localized: "voice.tense_fists"), rate: 0.5, pitch: 1.0)
    }

    func speakCountBackward() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .countBackward, fallbackText: String(localized: "voice.count_backward"), rate: 0.5, pitch: 1.0)
    }

    func speakAffirmStrong() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .affirmStrong, fallbackText: String(localized: "voice.affirm_strong"), rate: 0.5, pitch: 1.0)
    }

    func speakAffirmControl() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .affirmControl, fallbackText: String(localized: "voice.affirm_control"), rate: 0.5, pitch: 1.0)
    }

    func speakProgressiveRelax() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .progressiveRelax, fallbackText: String(localized: "voice.progressive_relax"), rate: 0.48, pitch: 0.95)
    }

    func speakMindfulNotice() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .mindfulNotice, fallbackText: String(localized: "voice.mindful_notice"), rate: 0.48, pitch: 0.95)
    }

    func speakGratitudeOne() {
        guard isVoiceEnabled else { return }
        smartSpeak(phrase: .gratitudeOne, fallbackText: String(localized: "voice.gratitude_one"), rate: 0.5, pitch: 1.0)
    }

    /// Останавливает всё воспроизведение
    func stop() {
        voiceBank?.stop()
        synthesizer.stopSpeaking(at: .immediate)
        // Восстанавливаем ambient вместо деактивации общей сессии
        ambientSound?.recoverSession()
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

    private static let log = Logger(
        subsystem: "MSK-PRODUKT.StopPanic",
        category: "AudioGuide"
    )

    @ObservationIgnored
    private var _isVoiceEnabled: Bool = {
        let ud = UserDefaults.standard
        // Migrate old key → new key (Phase 17)
        if ud.object(forKey: "audioGuideEnabled") == nil,
           ud.object(forKey: "voiceGuideEnabled") != nil {
            let old = ud.bool(forKey: "voiceGuideEnabled")
            ud.set(old, forKey: "audioGuideEnabled")
            ud.removeObject(forKey: "voiceGuideEnabled")
            return old
        }
        if ud.object(forKey: "audioGuideEnabled") != nil {
            return ud.bool(forKey: "audioGuideEnabled")
        }
        return true
    }()

    @ObservationIgnored
    private var _preferredSource: VoiceSource = {
        if let raw = UserDefaults.standard.string(forKey: "preferredVoiceSource"),
           let source = VoiceSource(rawValue: raw) {
            return source
        }
        return .voiceBank
    }()

    @ObservationIgnored
    private var _selectedVoiceId: String? = UserDefaults.standard.string(forKey: "selectedVoiceId")

    private let synthesizer = AVSpeechSynthesizer()
    private let speechDelegate = SpeechDelegate()

    /// Wire delegate + ambient ref. Called from AppCoordinator after injection.
    func configureSpeechDelegate() {
        speechDelegate.ambientSound = ambientSound
        synthesizer.delegate = speechDelegate
    }

    // MARK: - Smart Speak (single-tier: VoiceBank only — human voice, no robot)

    /// 2026-05-01: AVSpeech-fallback удалён по решению пользователя
    /// (см. obsiddian/StopPanic/Decisions/2026-05-01 — Voice and Cold-Start UX).
    /// Если фразы нет в VoiceBank — тишина (graceful), не synth-робот.
    /// Параметры fallbackText/rate/pitch оставлены в сигнатуре для совместимости
    /// со звонками из других сервисов, но fallback больше не выполняется.
    private func smartSpeak(
        phrase: VoiceBankService.Phrase,
        fallbackText: String,
        rate: Float = 0.45,
        pitch: Float = 1.0
    ) {
        _ = (fallbackText, rate, pitch) // silence "unused" warnings
        guard let vb = voiceBank, vb.play(phrase) else {
            Self.log.info("VoiceBank miss for \(phrase.rawValue) — silence (no robot fallback)")
            return
        }
        Self.log.info("Played from VoiceBank: \(phrase.rawValue)")
    }

    // MARK: - AVSpeech Fallback

    private func speakLocal(_ text: String, rate: Float = 0.5, pitch: Float = 1.0) {
        ensureAudioSession()

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = max(0.35, min(rate, AVSpeechUtteranceMaximumSpeechRate))
        utterance.pitchMultiplier = max(0.5, min(pitch, 2.0))
        let persistedVolume = UserDefaults.standard.object(forKey: "voiceBankVolume") as? Float ?? 1.0
        utterance.volume = max(0, min(1, persistedVolume))
        // Human-feel timing: thoughtful pause before, graceful tail after.
        // Prevents robotic "instant-start/abrupt-stop" cadence.
        utterance.preUtteranceDelay = 0.22
        utterance.postUtteranceDelay = 0.38
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

        // Within each quality tier, prefer female voices — research on calming-voice
        // perception in anxiety contexts (Keltner et al.) shows female-register
        // voices are perceived as warmer and reduce sympathetic arousal.
        func pickPreferringFemale(_ voices: [AVSpeechSynthesisVoice]) -> AVSpeechSynthesisVoice? {
            voices.first(where: { $0.gender == .female })
                ?? voices.first(where: { $0.gender == .unspecified })
                ?? voices.first
        }

        let premium = allVoices.filter { $0.quality == .premium }
        if let v = pickPreferringFemale(premium) { return v }

        let enhanced = allVoices.filter { $0.quality == .enhanced }
        if let v = pickPreferringFemale(enhanced) { return v }

        return pickPreferringFemale(allVoices) ?? AVSpeechSynthesisVoice(language: lang)
    }

    // MARK: - Audio Session

    private func ensureAudioSession() {
        AudioSessionManager.configureForSpeech()
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

// MARK: - AVSpeechSynthesizerDelegate (ambient recovery after speech)

@MainActor
private final class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    weak var ambientSound: AmbientSoundService?

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.ambientSound?.recoverSession()
        }
    }
}
