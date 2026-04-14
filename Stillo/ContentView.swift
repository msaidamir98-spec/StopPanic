import SwiftUI

struct ContentView: View {
    // MARK: Internal

    @Environment(AppCoordinator.self)
    var coordinator

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView {
                    withAnimation(SP.Anim.spring) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
            } else if !coordinator.hasAcceptedDisclaimer {
                MedicalDisclaimerView()
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
        .animation(SP.Anim.spring, value: coordinator.hasAcceptedDisclaimer)
        .animation(SP.Anim.spring, value: coordinator.hasSeenOnboarding)
    }

    // MARK: Private

    @State
    private var showSplash = true
}

#Preview {
    ContentView()
        .environment(AppCoordinator())
}
