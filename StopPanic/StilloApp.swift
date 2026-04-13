import BackgroundTasks
import SwiftUI
import UserNotifications

@main
struct StilloApp: App {
    // MARK: Internal

    @Environment(\.scenePhase)
    var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(coordinator)
                .preferredColorScheme(coordinator.themeManager.preferredColorScheme)
                .onReceive(NotificationCenter.default.publisher(for: .triggerSOSFromIntent)) { _ in
                    coordinator.triggerSOS()
                }
                .onReceive(NotificationCenter.default.publisher(for: .triggerBreathingFromIntent)) { _ in
                    coordinator.showBreathingSheet = true
                }
                .task {
                    // Start listening for StoreKit transactions
                    coordinator.premiumManager.listenForTransactions()
                    await coordinator.premiumManager.loadProducts()
                    await coordinator.premiumManager.checkSubscriptionStatus()
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
            Task {
                await coordinator.premiumManager.checkSubscriptionStatus()
            }
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
        UserDefaults.standard.synchronize()
        coordinator.diaryService.forceSave()
    }

    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.stillo.breathingReminder")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 3600)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("[Stillo] Failed to schedule background refresh: \(error)")
        }
    }

    private func scheduleBreathingNotification() async {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "notif_breathing_title")
        content.body = String(localized: "notif_breathing_body")
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "bg_breathing", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
