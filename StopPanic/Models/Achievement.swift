import Foundation

/// Достижения и геймификация
struct Achievement: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String              // SF Symbol
    let category: Category
    let requirement: Int
    var currentProgress: Int
    var isUnlocked: Bool
    var unlockedDate: Date?

    enum Category: String, Codable, CaseIterable {
        case streak = "Серия"
        case breathing = "Дыхание"
        case diary = "Дневник"
        case techniques = "Техники"
        case milestone = "Вехи"
    }

    var progress: Double {
        guard requirement > 0 else { return 0 }
        return min(Double(currentProgress) / Double(requirement), 1.0)
    }

    static let all: [Achievement] = [
        .init(id: "first_breath",       title: "Первый вдох",       description: "Завершите первое дыхательное упражнение",   icon: "wind",                      category: .breathing,   requirement: 1,  currentProgress: 0, isUnlocked: false),
        .init(id: "week_warrior",       title: "Воин недели",       description: "7 дней подряд без панической атаки",        icon: "flame.fill",                category: .streak,      requirement: 7,  currentProgress: 0, isUnlocked: false),
        .init(id: "diary_master",       title: "Мастер дневника",   description: "Запишите 30 записей в дневник",             icon: "book.fill",                 category: .diary,       requirement: 30, currentProgress: 0, isUnlocked: false),
        .init(id: "technique_explorer", title: "Исследователь",     description: "Попробуйте все 10 техник",                  icon: "star.fill",                 category: .techniques,  requirement: 10, currentProgress: 0, isUnlocked: false),
        .init(id: "calm_month",         title: "Спокойный месяц",   description: "30 дней подряд практики",                   icon: "trophy.fill",               category: .milestone,   requirement: 30, currentProgress: 0, isUnlocked: false),
    ]
}
