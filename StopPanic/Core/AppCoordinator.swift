import Observation
import SwiftUI

// MARK: - AppCoordinator

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
    let themeManager = ThemeManager.shared
    let premiumManager = PremiumManager.shared
    let streakService = StreakService()
    let reviewService = ReviewService.shared

    // MARK: - Navigation State

    var selectedTab: AppTab = .home
    var showSOSOverlay: Bool = false
    var showBreathingSheet: Bool = false
    var showPaywall: Bool = false

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
        case 5 ..< 12: return String(localized: "greeting_morning") + name
        case 12 ..< 17: return String(localized: "greeting_afternoon") + name
        case 17 ..< 22: return String(localized: "greeting_evening") + name
        default: return String(localized: "greeting_night") + name
        }
    }

    var motivationalMessage: String {
        let messages: [String.LocalizationValue] = [
            "motivation_1", "motivation_2", "motivation_3",
            "motivation_4", "motivation_5", "motivation_6", "motivation_7",
        ]
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return String(localized: messages[dayOfYear % messages.count])
    }

    func triggerSOS() {
        SP.Haptic.heavy()
        showSOSOverlay = true
        sosService.activateSOS()
        achievementService.updateProgress(id: "first_breath")
    }

    func completedSession() {
        sessionsCompleted += 1
        achievementService.updateProgress(id: "first_breath")
        streakService.recordActivity()
        reviewService.trackSessionCompleted()
        SP.Haptic.success()
    }

    func refreshPredictions() {
        predictionService.analyzePatterns(episodes: diaryService.diaryEpisodes)
    }
}

// MARK: - AppTab

enum AppTab: String, CaseIterable {
    case home
    case tools
    case heart
    case journal
    case profile

    // MARK: Internal

    var title: String {
        switch self {
        case .home: String(localized: "tab_home")
        case .tools: String(localized: "tab_tools")
        case .heart: String(localized: "tab_heart")
        case .journal: String(localized: "tab_journal")
        case .profile: String(localized: "tab_profile")
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .tools: "sparkles"
        case .heart: "heart.text.square.fill"
        case .journal: "book.fill"
        case .profile: "person.fill"
        }
    }
}
