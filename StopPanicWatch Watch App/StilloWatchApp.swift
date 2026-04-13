import SwiftUI

@main
struct StilloWatchApp: App {
    @StateObject private var heartService = WatchHeartService()
    @StateObject private var connectivity = WatchConnectionManager.shared
    
    var body: some Scene {
        WindowGroup {
            WatchTabView(heartService: heartService, connectivity: connectivity)
                .preferredColorScheme(.dark)
        }
    }
}
