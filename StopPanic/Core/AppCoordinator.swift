import SwiftUI
import Observation

// MARK: - App Coordinator
// Центральный объект, управляющий состоянием приложения.
// Единая точка DI — все сервисы создаются здесь и пробрасываются через Environment.

@Observable
@MainActor
final class AppCoordinator {
    
    // MARK: - Services (DI)
    let diaryService = DiaryService()
    let healthManager = HealthKitManager()
    let profileService = UserProfileService()
    let moodMapService = MoodMapService()
    let achievementService = AchievementService()
    let predictionService = PanicPredictionService()
    let sosService = SOSService()
    let notificationService = NotificationService()
    let watchConnectivity = WatchConnectivityService.shared
    
    // MARK: - Navigation State
    var selectedTab: AppTab = .home
    var showSOSOverlay: Bool = false
    var showBreathingSheet: Bool = false
    
    // MARK: - User State (persisted via UserDefaults)
    
    var hasSeenOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
        didSet { UserDefaults.standard.set(hasSeenOnboarding, forKey: "hasSeenOnboarding") }
    }
    
    var userName: String = UserDefaults.standard.string(forKey: "userName") ?? "" {
        didSet { UserDefaults.standard.set(userName, forKey: "userName") }
    }
    
    var panicExperience: String = UserDefaults.standard.string(forKey: "panicExperience") ?? "sometimes" {
        didSet { UserDefaults.standard.set(panicExperience, forKey: "panicExperience") }
    }
    
    var sessionsCompleted: Int = UserDefaults.standard.integer(forKey: "sessionsCompleted") {
        didSet { UserDefaults.standard.set(sessionsCompleted, forKey: "sessionsCompleted") }
    }
    
    var totalBreathingMinutes: Int = UserDefaults.standard.integer(forKey: "totalBreathingMinutes") {
        didSet { UserDefaults.standard.set(totalBreathingMinutes, forKey: "totalBreathingMinutes") }
    }
    
    // MARK: - Computed
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = userName.isEmpty ? "" : ", \(userName)"
        switch hour {
        case 5..<12:  return "Доброе утро\(name)"
        case 12..<17: return "Добрый день\(name)"
        case 17..<22: return "Добрый вечер\(name)"
        default:      return "Доброй ночи\(name)"
        }
    }
    
    var motivationalMessage: String {
        let messages = [
            "Ты в безопасности. Это место — для тебя.",
            "Каждый вдох — шаг к спокойствию.",
            "Сегодня ты сильнее вчерашней тревоги.",
            "Паника временна. Ты — постоянен.",
            "Дыши. Чувствуй. Ты здесь.",
            "Тревога — гость. Ты — хозяин.",
            "Ты уже справлялся. Справишься и сейчас.",
        ]
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return messages[dayOfYear % messages.count]
    }
    
    // MARK: - Actions
    
    func triggerSOS() {
        SP.Haptic.heavy()
        showSOSOverlay = true
        sosService.activateSOS()
        achievementService.updateProgress(id: "first_breath")
    }
    
    func completedSession() {
        sessionsCompleted += 1
        achievementService.updateProgress(id: "first_breath")
        SP.Haptic.success()
    }
    
    func refreshPredictions() {
        predictionService.analyzePatterns(episodes: diaryService.diaryEpisodes)
    }
}

// MARK: - Tab Enum

enum AppTab: String, CaseIterable {
    case home       = "Главная"
    case tools      = "Техники"
    case heart      = "Сердце"
    case journal    = "Дневник"
    case profile    = "Профиль"
    
    var icon: String {
        switch self {
        case .home:     return "house.fill"
        case .tools:    return "sparkles"
        case .heart:    return "heart.text.square.fill"
        case .journal:  return "book.fill"
        case .profile:  return "person.fill"
        }
    }
}
