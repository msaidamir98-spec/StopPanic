//
//  ContentView.swift
//  StopPanic
//
//  Created by Саид Магдиев on 24.12.2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppCoordinator.self) var coordinator
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView {
                    withAnimation(SP.Anim.spring) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
            } else if !coordinator.hasSeenOnboarding {
                OnboardingFlowView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(SP.Anim.spring, value: showSplash)
        .animation(SP.Anim.spring, value: coordinator.hasSeenOnboarding)
    }
}

#Preview {
    ContentView()
        .environment(AppCoordinator())
}
