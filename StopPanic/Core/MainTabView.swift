import SwiftUI

// MARK: - Main Tab View — Premium
// 5 tabs, Apple HIG. SOS overlay accessible from any tab.
// ✨ Glass tab bar, smooth transitions

struct MainTabView: View {
    @Environment(AppCoordinator.self) var coordinator
    
    var body: some View {
        @Bindable var coordinator = coordinator
        ZStack {
            TabView(selection: $coordinator.selectedTab) {
                HomeScreenView()
                    .tabItem {
                        Label(AppTab.home.rawValue, systemImage: AppTab.home.icon)
                    }
                    .tag(AppTab.home)
                
                ToolsHubView()
                    .tabItem {
                        Label(AppTab.tools.rawValue, systemImage: AppTab.tools.icon)
                    }
                    .tag(AppTab.tools)
                
                NavigationStack {
                    HeartAnalysisView()
                }
                .tabItem {
                    Label(AppTab.heart.rawValue, systemImage: AppTab.heart.icon)
                }
                .tag(AppTab.heart)
                
                JournalView()
                    .tabItem {
                        Label(AppTab.journal.rawValue, systemImage: AppTab.journal.icon)
                    }
                    .tag(AppTab.journal)
                
                ProfileHubView()
                    .tabItem {
                        Label(AppTab.profile.rawValue, systemImage: AppTab.profile.icon)
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
        }
        .animation(SP.Anim.spring, value: coordinator.showSOSOverlay)
        .onAppear {
            configureTabBarAppearance()
            coordinator.refreshPredictions()
        }
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(SP.Colors.bgElevated)
        
        // Add top border line
        appearance.shadowColor = UIColor(white: 1, alpha: 0.06)
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(SP.Colors.textTertiary)
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(SP.Colors.textTertiary)]
        itemAppearance.selected.iconColor = UIColor(SP.Colors.accent)
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(SP.Colors.accent)]
        
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
