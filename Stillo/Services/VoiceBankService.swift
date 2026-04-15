import AVFoundation
import os.log

// MARK: - VoiceBankService

/// Менеджер предзаписанных голосовых фраз.
/// Все аудио хранятся в бандле → никакого интернета, мгновенное воспроизведение.
/// Фразы разложены по языкам: Resources/Voice/{en,ru}/phrase.mp3
///
/// Приоритет при подборе языка:
///   1. Точное совпадение (ru → ru/)
///   2. Английский фолбэк (en/)
///   3. nil → AudioGuideService уйдёт в AVSpeech
///
/// Аудиосессия: НЕ деактивируется после каждой фразы.
/// Вместо setActive(false) восстанавливаем ambient-сессию через recoverSession().

@MainActor
@Observable
final class VoiceBankService {
    // MARK: - Phrase Keys

    /// Все фразы, которые озвучивает голосовой помощник.
    /// Имя rawValue = имя файла (без .mp3).
    enum Phrase: String, CaseIterable {
        // Breathing
        case breatheIn      = "breathe_in"
        case hold           = "hold"
        case breatheOut     = "breathe_out"

        // Grounding 5-4-3-2-1
        case groundSee      = "ground_see"
        case groundTouch    = "ground_touch"
        case groundHear     = "ground_hear"
        case groundSmell    = "ground_smell"
        case groundTaste    = "ground_taste"

        // Completions / affirmations
        case youDidIt       = "you_did_it"
        case youAreSafe     = "you_are_safe"
        case welcome        = "welcome"
        case sessionStart   = "session_start"
        case greatJob       = "great_job"
        case almostDone     = "almost_done"
        case relaxShoulders = "relax_shoulders"
        case closeEyes      = "close_eyes"
        case focusBreath    = "focus_breath"

        // SOS
        case panicIntro     = "panic_intro"
        case sosCalmDown    = "sos_calm"

        // CBT & Grounding (new — medically grounded)
        case bodyRelax      = "body_relax"
        case feetOnFloor    = "feet_on_floor"
        case safePlace      = "safe_place"
        case notInDanger    = "not_in_danger"
        case thisWillPass   = "this_will_pass"
        case slowDown       = "slow_down"
        case nameObjects    = "name_objects"
        case coldWater      = "cold_water"
        case tenseFists     = "tense_fists"
        case countBackward  = "count_backward"
        case affirmStrong   = "affirm_strong"
        case affirmControl  = "affirm_control"
        case progressiveRelax = "progressive_relax"
        case mindfulNotice  = "mindful_notice"
        case gratitudeOne   = "gratitude_one"
    }

    // MARK: - Dependency (for session recovery)

    /// Ссылка на AmbientSoundService для восстановления сессии после фразы
    var ambientSound: AmbientSoundService?

    // MARK: - State

    /// Включён ли голосовой помощник
    var isEnabled: Bool {
        get {
            access(keyPath: \.isEnabled)
            return _isEnabled
        }
        set {
            withMutation(keyPath: \.isEnabled) {
                _isEnabled = newValue
                UserDefaults.standard.set(newValue, forKey: "voiceGuideEnabled")
                if !newValue { stop() }
            }
        }
    }

    /// Идёт ли сейчас воспроизведение
    var isPlaying: Bool {
        get {
            access(keyPath: \.isPlaying)
            return _isPlaying
        }
        set {
            withMutation(keyPath: \.isPlaying) {
                _isPlaying = newValue
            }
        }
    }

    /// Громкость голоса (0.0–1.0)
    var volume: Float {
        get {
            access(keyPath: \.volume)
            return _volume
        }
        set {
            withMutation(keyPath: \.volume) {
                _volume = max(0, min(1, newValue))
                UserDefaults.standard.set(_volume, forKey: "voiceBankVolume")
                player?.volume = _volume
            }
        }
    }

    // MARK: - Public API

    /// Воспроизвести фразу. Возвращает `true` если файл найден и играет.
    @discardableResult
    func play(_ phrase: Phrase) -> Bool {
        guard isEnabled else { return false }

        guard let url = audioURL(for: phrase) else {
            let lang = currentLanguageCode
            Self.log.warning("No audio file for \(phrase.rawValue) [\(lang)]")
            return false
        }

        return playFile(url: url)
    }

    /// Остановить текущее воспроизведение
    func stop() {
        player?.stop()
        isPlaying = false
    }

    /// Проверяет, доступна ли фраза в бандле для текущего языка
    func hasPhrase(_ phrase: Phrase) -> Bool {
        audioURL(for: phrase) != nil
    }

    /// Количество доступных фраз для текущего языка
    var availablePhraseCount: Int {
        Phrase.allCases.filter { hasPhrase($0) }.count
    }

    /// Предзагрузить все фразы в кэш URL (вызывается при запуске)
    func warmUp() {
        let lang = currentLanguageCode
        for phrase in Phrase.allCases {
            let key = "\(lang)_\(phrase.rawValue)"
            if urlCache[key] == nil {
                urlCache[key] = findAudioFile(phrase: phrase.rawValue, language: lang)
            }
        }
        let count = availablePhraseCount
        Self.log.info("VoiceBank warmed up: \(count)/\(Phrase.allCases.count) phrases for [\(lang)]")
    }

    // MARK: - Private

    private static let log = Logger(
        subsystem: "MSK-PRODUKT.StopPanic",
        category: "VoiceBank"
    )

    @ObservationIgnored
    private var _isEnabled: Bool = {
        if UserDefaults.standard.object(forKey: "voiceGuideEnabled") != nil {
            return UserDefaults.standard.bool(forKey: "voiceGuideEnabled")
        }
        return true // default ON
    }()

    @ObservationIgnored
    private var _isPlaying = false

    @ObservationIgnored
    private var _volume: Float = {
        let v = UserDefaults.standard.float(forKey: "voiceBankVolume")
        return v > 0 ? v : 0.85 // default 85%
    }()

    @ObservationIgnored
    private var player: AVAudioPlayer?

    /// Cache: "en_breathe_in" → URL
    @ObservationIgnored
    private var urlCache: [String: URL] = [:]

    // MARK: - Language

    private var currentLanguageCode: String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        // Поддерживаемые языки с озвучкой
        let supported = ["en", "ru"]
        return supported.contains(code) ? code : "en"
    }

    // MARK: - File Lookup

    /// Ищет аудиофайл в бандле: сначала точный язык, потом en-фолбэк.
    /// Файлы именуются: {lang}_{phrase}.mp3 (например en_breathe_in.mp3)
    private func audioURL(for phrase: Phrase) -> URL? {
        let lang = currentLanguageCode
        let key = "\(lang)_\(phrase.rawValue)"

        if let cached = urlCache[key] {
            return cached
        }

        // 1) Try exact language
        if let url = findAudioFile(phrase: phrase.rawValue, language: lang) {
            urlCache[key] = url
            return url
        }

        // 2) English fallback
        if lang != "en" {
            let enKey = "en_\(phrase.rawValue)"
            if let cached = urlCache[enKey] { return cached }
            if let url = findAudioFile(phrase: phrase.rawValue, language: "en") {
                urlCache[enKey] = url
                return url
            }
        }

        return nil
    }

    /// Поиск файла в бандле — несколько стратегий.
    /// Файлы хранятся как {lang}_{phrase}.mp3 для уникальности в flat copy.
    private func findAudioFile(phrase: String, language: String) -> URL? {
        let bundle = Bundle.main
        let fileName = "\(language)_\(phrase)"

        // Strategy 1: Direct lookup (Xcode copies to flat bundle root)
        if let url = bundle.url(forResource: fileName, withExtension: "mp3") {
            return url
        }

        // Strategy 2: In Voice/lang/ subdirectory (folder reference)
        if let url = bundle.url(forResource: fileName, withExtension: "mp3", subdirectory: "Voice/\(language)") {
            return url
        }

        // Strategy 3: Recursive search for lang_phrase.mp3
        if let resourcePath = bundle.resourcePath {
            let target = "\(fileName).mp3"
            if let enumerator = FileManager.default.enumerator(atPath: resourcePath) {
                while let path = enumerator.nextObject() as? String {
                    if path.hasSuffix(target) {
                        return URL(fileURLWithPath: resourcePath).appendingPathComponent(path)
                    }
                }
            }
        }

        return nil
    }

    // MARK: - Playback

    private func playFile(url: URL) -> Bool {
        do {
            ensureSession()

            if let existing = player, existing.isPlaying {
                existing.stop()
            }

            let p = try AVAudioPlayer(contentsOf: url)
            p.volume = 0 // start silent
            p.prepareToPlay()
            p.play()
            player = p
            isPlaying = true

            // Soft fade-in (0.25s)
            p.setVolume(_volume, fadeDuration: 0.25)

            // Monitor completion — restore ambient session when done
            Task { [weak self] in
                while p.isPlaying {
                    try? await Task.sleep(for: .milliseconds(80))
                }
                await MainActor.run {
                    self?.isPlaying = false
                    // Восстанавливаем ambient-сессию вместо деактивации
                    self?.ambientSound?.recoverSession()
                }
            }

            Self.log.info("Playing: \(url.lastPathComponent)")
            return true
        } catch {
            Self.log.error("Playback failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Audio Session

    /// Категория .playback + .spokenAudio + duckOthers
    /// — приглушает музыку, но не останавливает
    /// — НЕ вызывает setActive(false) после — чтобы не убивать ambient
    private func ensureSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers]
            )
            try session.setActive(true)
        } catch {
            Self.log.error("Audio session error: \(error.localizedDescription)")
        }
    }
}
