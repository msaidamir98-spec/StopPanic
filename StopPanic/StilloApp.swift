import BackgroundTasks
import SwiftUI

@main
struct StilloApp: App {
    // MARK: Internal

    @Environment(\.scenePhase)
    var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(coordinator)
                .onReceive(NotificationCenter.default.publisher(for: .triggerSOSFromIntent)) { _ in
                    coordinator.triggerSOS()
                }
                .onReceive(NotificationCenter.default.publisher(for: .triggerBreathingFromIntent)) { _ in
                    coordinator.showBreathingSheet = true
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhase(newPhase)
        }
        .backgroundTask(.appRefresh("com.stillo.breathingReminder")) {
            await scheduleBreathingNotification()
        }
    }

    // MARK: Private

    @State
    private var coordinator = AppCoordinator()

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            coordinator.refreshPredictions()
        case .inactive:
            break
        case .background:
            saveAppState()
            scheduleAppRefresh()
        @unknown default:
            break
        }
    }

    private func saveAppState() {
        // Force sync UserDefaults before suspension
        UserDefaults.standard.synchronize()
        // Persist diary data
        coordinator.diaryService.forceSave()
    }

    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.stillo.breathingReminder")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 3600) // 4 hours
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("[Stillo] Failed to schedule background refresh: \(error)")
        }
    }

    private func scheduleBreathingNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Время для дыхания 🌬️"
        content.body = "2 минуты техники 4-7-8 снизят тревогу. Попробуй сейчас."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "bg_breathing", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }
}

import UserNotifications
