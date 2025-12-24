//
//  StopPanicApp.swift
//  StopPanic
//
//  Created by Саид Магдиев on 24.12.2025.
//

import SwiftUI

@main
struct StopPanicApp: App {
    @State private var coordinator = AppCoordinator()

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
}
