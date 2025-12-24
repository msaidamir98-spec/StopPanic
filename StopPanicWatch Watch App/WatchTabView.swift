import SwiftUI

/// Главный TabView для Apple Watch — vertical page navigation
struct WatchTabView: View {
    @ObservedObject var heartService: WatchHeartService
    @ObservedObject var connectivity: WatchConnectionManager
    
    var body: some View {
        TabView {
            WatchHomeView(heartService: heartService, connectivity: connectivity)
            WatchBreathingView(connectivity: connectivity)
            WatchDifferentialView()
            WatchSOSView(connectivity: connectivity)
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview {
    WatchTabView(heartService: WatchHeartService(), connectivity: WatchConnectionManager.shared)
}
