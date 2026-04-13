import Foundation

/// Достижения и геймификация
struct Achievement: Codable, Identifiable {
    enum Category: String, Codable, CaseIterable {
        case streak = "streak"
        case breathing = "breathing"
        case diary = "diary"
        case techniques = "techniques"
        case milestone = "milestone"

        var localizedTitle: String {
            switch self {
            case .streak: String(localized: "achievement.cat_streak")
            case .breathing: String(localized: "achievement.cat_breathing")
            case .diary: String(localized: "achievement.cat_diary")
            case .techniques: String(localized: "achievement.cat_techniques")
            case .milestone: String(localized: "achievement.cat_milestone")
            }
        }
    }

    static let all: [Self] = [
        .init(
            id: "first_breath",
            title: String(localized: "achievement.first_breath_title"),
            description: String(localized: "achievement.first_breath_desc"),
            icon: "wind",
            category: .breathing,
            requirement: 1,
            currentProgress: 0,
            isUnlocked: false
        ),
        .init(
            id: "week_warrior",
            title: String(localized: "achievement.week_warrior_title"),
            description: String(localized: "achievement.week_warrior_desc"),
            icon: "flame.fill",
            category: .streak,
            requirement: 7,
            currentProgress: 0,
            isUnlocked: false
        ),
        .init(
            id: "diary_master",
            title: String(localized: "achievement.diary_master_title"),
            description: String(localized: "achievement.diary_master_desc"),
            icon: "book.fill",
            category: .diary,
            requirement: 30,
            currentProgress: 0,
            isUnlocked: false
        ),
        .init(
            id: "technique_explorer",
            title: String(localized: "achievement.technique_explorer_title"),
            description: String(localized: "achievement.technique_explorer_desc"),
            icon: "star.fill",
            category: .techniques,
            requirement: 10,
            currentProgress: 0,
            isUnlocked: false
        ),
        .init(
            id: "calm_month",
            title: String(localized: "achievement.calm_month_title"),
            description: String(localized: "achievement.calm_month_desc"),
            icon: "trophy.fill",
            category: .milestone,
            requirement: 30,
            currentProgress: 0,
            isUnlocked: false
        ),
    ]

    let id: String
    let title: String
    let description: String
    let icon: String // SF Symbol
    let category: Category
    let requirement: Int
    var currentProgress: Int
    var isUnlocked: Bool
    var unlockedDate: Date?

    var progress: Double {
        guard requirement > 0 else { return 0 }
        return min(Double(currentProgress) / Double(requirement), 1.0)
    }
}
