import SwiftUI

@main
struct StilloApp: App {
    // MARK: Internal

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
    }

    // MARK: Private

    @State
    private var coordinator = AppCoordinator()
}
