import SwiftUI

@main
struct StopPanicWatchApp: App {
    @StateObject private var heartService = WatchHeartService()
    @StateObject private var connectivity = WatchConnectionManager.shared
    
    var body: some Scene {
        WindowGroup {
            WatchTabView(heartService: heartService, connectivity: connectivity)
                .preferredColorScheme(.dark)
        }
    }
}
