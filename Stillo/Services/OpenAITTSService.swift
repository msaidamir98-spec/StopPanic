import AVFoundation
import Foundation
import os.log
import Security

// MARK: - OpenAITTSService

/// Голосовой помощник через OpenAI TTS API.
/// Отправляет текст → получает mp3 → кэширует на диск → плавно воспроизводит.
/// Голоса: alloy, echo, fable, onyx, nova, shimmer — человечные, тёплые.
@MainActor
@Observable
final class OpenAITTSService {
    // MARK: - Public Types

    enum TTSVoice: String, CaseIterable, Identifiable {
        case alloy, echo, fable, onyx, nova, shimmer
        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .alloy: "Alloy — нейтральный"
            case .echo: "Echo — мужской, спокойный"
            case .fable: "Fable — тёплый, рассказчик"
            case .onyx: "Onyx — глубокий, уверенный"
            case .nova: "Nova — женский, мягкий"
            case .shimmer: "Shimmer — светлый, нежный"
            }
        }

        var emoji: String {
            switch self {
            case .alloy: "🔵"
            case .echo: "🟣"
            case .fable: "🟠"
            case .onyx: "⚫"
            case .nova: "🩷"
            case .shimmer: "✨"
            }
        }
    }

    enum TTSModel: String, CaseIterable {
        case tts1 = "tts-1"
        case tts1HD = "tts-1-hd"

        var displayName: String {
            switch self {
            case .tts1: "Standard"
            case .tts1HD: "HD (slower)"
            }
        }
    }

    // MARK: - State

    var isEnabled: Bool {
        get {
            access(keyPath: \.isEnabled)
            return _isEnabled
        }
        set {
            withMutation(keyPath: \.isEnabled) {
                _isEnabled = newValue
                UserDefaults.standard.set(newValue, forKey: "openai_tts_enabled")
            }
        }
    }

    var apiKey: String {
        get {
            access(keyPath: \.apiKey)
            return _apiKey
        }
        set {
            withMutation(keyPath: \.apiKey) {
                _apiKey = newValue
                KeychainHelper.save(key: "openai_api_key", value: newValue)
            }
        }
    }

    var selectedVoice: TTSVoice {
        get {
            access(keyPath: \.selectedVoice)
            return _selectedVoice
        }
        set {
            withMutation(keyPath: \.selectedVoice) {
                _selectedVoice = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: "openai_tts_voice")
            }
        }
    }

    var selectedModel: TTSModel {
        get {
            access(keyPath: \.selectedModel)
            return _selectedModel
        }
        set {
            withMutation(keyPath: \.selectedModel) {
                _selectedModel = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: "openai_tts_model")
            }
        }
    }

    var isSpeaking: Bool {
        get {
            access(keyPath: \.isSpeaking)
            return _isSpeaking
        }
        set {
            withMutation(keyPath: \.isSpeaking) {
                _isSpeaking = newValue
            }
        }
    }

    var isLoading: Bool {
        get {
            access(keyPath: \.isLoading)
            return _isLoading
        }
        set {
            withMutation(keyPath: \.isLoading) {
                _isLoading = newValue
            }
        }
    }

    /// Is API key configured and service enabled?
    var isReady: Bool {
        isEnabled && !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Public API

    /// Speak text through OpenAI TTS with caching
    func speak(_ text: String, speed: Double = 0.85) {
        guard isReady else { return }
        let cacheKey = "\(selectedVoice.rawValue)_\(selectedModel.rawValue)_\(text.hashValue)"
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                let audioURL: URL
                if let cached = cacheURL(for: cacheKey), FileManager.default.fileExists(atPath: cached.path) {
                    Self.log.info("Playing cached TTS: \(cacheKey)")
                    audioURL = cached
                } else {
                    Self.log.info("Fetched and cached TTS: \(cacheKey)")
                    audioURL = try await fetchAndCache(text: text, speed: speed, cacheKey: cacheKey)
                }
                try await playAudio(url: audioURL)
            } catch {
                Self.log.error("OpenAI TTS failed: \(error.localizedDescription)")
            }
        }
    }

    /// Speak breath phase
    func speakBreathPhase(_ phase: String) {
        speak(phase, speed: 0.8)
    }

    /// Stop playback
    func stop() {
        player?.stop()
        isSpeaking = false
        deactivateSession()
    }

    /// Clear all cached audio files
    func clearCache() {
        guard let dir = cacheDirectory else { return }
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        Self.log.info("TTS cache cleared")
    }

    // MARK: - Private

    private static let log = Logger(subsystem: "MSK-PRODUKT.StopPanic", category: "OpenAITTS")

    @ObservationIgnored
    private var _isEnabled: Bool = UserDefaults.standard.bool(forKey: "openai_tts_enabled")
    @ObservationIgnored
    private var _apiKey: String = KeychainHelper.load(key: "openai_api_key") ?? ""
    @ObservationIgnored
    private var _selectedVoice: TTSVoice = TTSVoice(rawValue: UserDefaults.standard.string(forKey: "openai_tts_voice") ?? "") ?? .nova
    @ObservationIgnored
    private var _selectedModel: TTSModel = TTSModel(rawValue: UserDefaults.standard.string(forKey: "openai_tts_model") ?? "") ?? .tts1
    @ObservationIgnored
    private var _isSpeaking = false
    @ObservationIgnored
    private var _isLoading = false
    @ObservationIgnored
    nonisolated(unsafe) private var player: AVAudioPlayer?
    @ObservationIgnored
    private var sessionActive = false

    // MARK: - Audio Session

    private func ensureSession() {
        guard !sessionActive else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
            sessionActive = true
        } catch {
            Self.log.error("Audio session setup failed: \(error.localizedDescription)")
        }
    }

    private func deactivateSession() {
        guard sessionActive else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            sessionActive = false
        } catch {
            Self.log.error("Audio session deactivation failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Network

    private func fetchAndCache(text: String, speed: Double, cacheKey: String) async throws -> URL {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw TTSError.noAPIKey
        }
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/speech")!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        let body: [String: Any] = [
            "model": selectedModel.rawValue,
            "input": text,
            "voice": selectedVoice.rawValue,
            "response_format": "mp3",
            "speed": speed,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw TTSError.invalidResponse
        }
        guard http.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown"
            Self.log.error("OpenAI API error \(http.statusCode): \(errorText)")
            throw TTSError.apiError(http.statusCode, errorText)
        }
        // Save to cache
        let fileURL = cacheURL(for: cacheKey)!
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL)
        return fileURL
    }

    // MARK: - Playback

    private func playAudio(url: URL) async throws {
        ensureSession()
        let p = try AVAudioPlayer(contentsOf: url)
        p.volume = 0.0 // start silent for fade-in
        p.prepareToPlay()
        p.play()
        player = p
        isSpeaking = true
        // Fade in over 0.3s
        p.setVolume(0.9, fadeDuration: 0.3)
        // Wait for playback to finish
        while p.isPlaying {
            try await Task.sleep(for: .milliseconds(100))
        }
        isSpeaking = false
        deactivateSession()
    }

    // MARK: - Cache

    private var cacheDirectory: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("tts_cache", isDirectory: true)
    }

    private func cacheURL(for key: String) -> URL? {
        cacheDirectory?.appendingPathComponent("\(key).mp3")
    }

    // MARK: - Errors

    enum TTSError: LocalizedError {
        case noAPIKey
        case invalidResponse
        case apiError(Int, String)

        var errorDescription: String? {
            switch self {
            case .noAPIKey: "OpenAI API key is not configured"
            case .invalidResponse: "Invalid response from OpenAI"
            case .apiError(let code, let msg): "API error \(code): \(msg)"
            }
        }
    }
}

// MARK: - KeychainHelper

/// Minimal Keychain wrapper for storing API key securely
enum KeychainHelper {
    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        SecItemAdd(add as CFDictionary, nil)
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
