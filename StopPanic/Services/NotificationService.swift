import Foundation
import UserNotifications
import Combine

/// Сервис локальных уведомлений
@MainActor
final class NotificationService: ObservableObject {
    @Published var isAuthorized: Bool = false

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

    /// Напоминание о дыхательной практике
    func scheduleBreathingReminder(hour: Int = 10, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "Время для дыхания 🌬️"
        content.body = "2 минуты техники 4-7-8 снизят тревогу. Попробуй сейчас."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "breathing_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
