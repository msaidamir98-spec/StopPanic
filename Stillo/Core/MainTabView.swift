import SwiftUI

// MARK: - MainTabView

// 5 tabs, Apple HIG. SOS overlay accessible from any tab.
// Shake gesture → triggers SOS immediately.

struct MainTabView: View {
    // MARK: Internal

    @Environment(AppCoordinator.self)
    var coordinator

    var body: some View {
        @Bindable
        var coordinator = coordinator
        ZStack {
            TabView(selection: $coordinator.selectedTab) {
                HomeScreenView()
                    .tabItem {
                        Label(AppTab.home.title, systemImage: AppTab.home.icon)
                    }
                    .tag(AppTab.home)

                ToolsHubView()
                    .tabItem {
                        Label(AppTab.tools.title, systemImage: AppTab.tools.icon)
                    }
                    .tag(AppTab.tools)

                NavigationStack {
                    HeartAnalysisView()
                }
                .tabItem {
                    Label(AppTab.heart.title, systemImage: AppTab.heart.icon)
                }
                .tag(AppTab.heart)

                JournalView()
                    .tabItem {
                        Label(AppTab.journal.title, systemImage: AppTab.journal.icon)
                    }
                    .tag(AppTab.journal)

                ProfileHubView()
                    .tabItem {
                        Label(AppTab.profile.title, systemImage: AppTab.profile.icon)
                    }
                    .tag(AppTab.profile)
            }
            .tint(SP.Colors.accent)

            // SOS Fullscreen Overlay
            if coordinator.showSOSOverlay {
                SOSFlowView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(100)
            }

            // Paywall Sheet
        }
        .sheet(isPresented: $coordinator.showPaywall) {
            PaywallView()
                .environment(coordinator)
        }
        .animation(SP.Anim.spring, value: coordinator.showSOSOverlay)
        .onAppear {
            configureAppearance()
            coordinator.refreshPredictions()
        }
        .onChange(of: coordinator.themeManager.currentTheme) { _, _ in
            configureAppearance()
            refreshAllBarAppearances()
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .onShake {
            if !coordinator.showSOSOverlay {
                coordinator.triggerSOS()
            }
        }
    }

    // MARK: Private

    private func configureAppearance() {
        let theme = coordinator.themeManager

        // MARK: Tab Bar

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(theme.bgElevated)
        tabAppearance.shadowColor = theme.isLight
            ? UIColor(theme.textTertiary.opacity(0.1))
            : UIColor(white: 1, alpha: 0.06)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(theme.textTertiary)
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(theme.textTertiary)]
        itemAppearance.selected.iconColor = UIColor(theme.accent)
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(theme.accent)]

        tabAppearance.stackedLayoutAppearance = itemAppearance
        tabAppearance.inlineLayoutAppearance = itemAppearance
        tabAppearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // MARK: Navigation Bar

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(theme.bg)
        navAppearance.shadowColor = .clear
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(theme.textPrimary)]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(theme.textPrimary)]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(theme.accent)
    }

    /// Force all windows to re-layout after theme change
    /// This fixes SafeArea / NavigationBar color staying stale.
    private func refreshAllBarAppearances() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene else { continue }
                for window in windowScene.windows {
                    let currentRootVC = window.rootViewController
                    window.rootViewController = nil
                    window.rootViewController = currentRootVC
                    window.setNeedsLayout()
                    window.layoutIfNeeded()
                }
            }
        }
    }

    /// Handle deep links: stillo://sos, stillo://breathing
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "stillo" else { return }
        switch url.host {
        case "sos":
            coordinator.triggerSOS()
        case "breathing":
            coordinator.showBreathingSheet = true
        default: break
        }
    }
}

// MARK: - Shake Gesture Support

/// Detects shake gesture and triggers SOS — hands-free crisis activation
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceShaken, object: nil)
        }
    }
}

extension Notification.Name {
    static let deviceShaken = Notification.Name("deviceShaken")
}

// MARK: - ShakeDetector

struct ShakeDetector: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .deviceShaken)) { _ in
                action()
            }
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        modifier(ShakeDetector(action: action))
    }
}
