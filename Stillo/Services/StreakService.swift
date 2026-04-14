import Foundation
import Observation

// MARK: - StreakService

/// Streak system — ежедневные серии для retention.
/// Streak увеличивается при любом действии: дыхание, дневник, MoodMap.
/// При пропуске дня — streak сбрасывается.
@Observable
@MainActor
final class StreakService {
    // MARK: Lifecycle

    init() {
        currentStreak = UserDefaults.standard.integer(forKey: Self.streakKey)
        bestStreak = UserDefaults.standard.integer(forKey: Self.bestStreakKey)
        if let last = UserDefaults.standard.object(forKey: Self.lastDateKey) as? Date {
            lastActiveDate = last
        }
        checkStreakContinuity()
    }

    // MARK: Internal

    /// Текущая серия дней
    private(set) var currentStreak: Int {
        didSet { UserDefaults.standard.set(currentStreak, forKey: Self.streakKey) }
    }

    /// Лучшая серия
    private(set) var bestStreak: Int {
        didSet { UserDefaults.standard.set(bestStreak, forKey: Self.bestStreakKey) }
    }

    /// Были ли действия сегодня
    var isActiveToday: Bool {
        guard let last = lastActiveDate else { return false }
        return Calendar.current.isDateInToday(last)
    }

    /// Регистрация активности (дыхание, дневник, etc.)
    func recordActivity() {
        let calendar = Calendar.current
        let now = Date()

        if let last = lastActiveDate {
            if calendar.isDateInToday(last) {
                // Уже активен сегодня
                return
            } else if calendar.isDateInYesterday(last) {
                // Продолжение серии
                currentStreak += 1
            } else {
                // Пропуск — начало новой серии
                currentStreak = 1
            }
        } else {
            // Первая активность
            currentStreak = 1
        }

        lastActiveDate = now
        if currentStreak > bestStreak {
            bestStreak = currentStreak
        }
    }

    // MARK: Private

    private static let streakKey = "stillo_streak_current"
    private static let bestStreakKey = "stillo_streak_best"
    private static let lastDateKey = "stillo_streak_last_date"

    private var lastActiveDate: Date? {
        didSet {
            if let date = lastActiveDate {
                UserDefaults.standard.set(date, forKey: Self.lastDateKey)
            }
        }
    }

    /// При запуске — проверить, не сломана ли серия
    private func checkStreakContinuity() {
        guard let last = lastActiveDate else {
            currentStreak = 0
            return
        }

        let calendar = Calendar.current
        if calendar.isDateInToday(last) || calendar.isDateInYesterday(last) {
            // Серия жива
        } else {
            // Серия прервана
            currentStreak = 0
        }
    }
}
