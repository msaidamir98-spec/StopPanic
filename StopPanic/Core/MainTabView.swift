import SwiftUI

// MARK: - Main Tab View — Premium

// 5 tabs, Apple HIG. SOS overlay accessible from any tab.

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
}
