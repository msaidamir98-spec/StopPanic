import Combine
import Foundation
import UserNotifications

/// Smart notification service — breathing reminders, streak alerts, retention
@MainActor
final class NotificationService: ObservableObject {
    @Published
    var isAuthorized: Bool = false

    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            let service = self
            Task { @MainActor in
                service?.isAuthorized = granted
            }
        }
    }

    /// Alias for backward compatibility
    func requestAuthorization() {
        requestPermissions()
    }

    /// Daily breathing reminder
    func scheduleBreathingReminder(hour: Int = 10, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notif_breathing_title")
        content.body = String(localized: "notif_breathing_body")
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "breathing_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Streak reminder — "Don't lose your X-day streak!"
    func scheduleStreakReminder(currentStreak: Int) {
        guard currentStreak >= 2 else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notif_streak_title")
        content.body = String(localized: "notif_streak_body \(currentStreak)")
        content.sound = .default

        // 8pm reminder
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "streak_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Evening reflection reminder
    func scheduleEveningReflection() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notif_reflection_title")
        content.body = String(localized: "notif_reflection_body")
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 30

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "evening_reflection", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Motivational morning
    func scheduleMorningMotivation() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notif_morning_title")
        content.body = String(localized: "notif_morning_body")
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 30

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_motivation", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Smart Absence Reminder

    /// 2026-05-03 (Master Plan День 3): мягкое напоминание после
    /// заданного периода без активности. Не пушит «давайте позанимаемся» —
    /// тон спокойный, тревожной аудитории нужен опт-аут давления.
    ///
    /// Вызывать после каждой завершённой SOS-сессии или mood-snapshot.
    /// Каждый вызов отменяет предыдущее напоминание и ставит новое
    /// (sliding window). Если юзер активен — он его никогда не увидит.
    ///
    /// - Parameter days: через сколько дней неактивности показать
    ///   напоминание. По умолчанию 3 дня (72 часа).
    func rescheduleAbsenceReminder(afterDays days: Int = 3) {
        let identifier = "absence_reminder"
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notif_absence_title")
        content.body = String(localized: "notif_absence_body")
        content.sound = .default
        content.interruptionLevel = .passive  // не яркое, спокойное напоминание

        let interval = TimeInterval(days * 24 * 3_600)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    /// Полностью отключить smart-reminders (вызывается из Settings toggle).
    func cancelAbsenceReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["absence_reminder"])
    }
}
