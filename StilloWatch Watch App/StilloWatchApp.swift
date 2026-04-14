import SwiftUI

@main
struct StilloWatchApp: App {
    // MARK: Internal

    var body: some Scene {
        WindowGroup {
            WatchTabView(heartService: heartService, connectivity: connectivity)
                .preferredColorScheme(.dark)
        }
    }

    // MARK: Private

    @StateObject
    private var heartService = WatchHeartService()
    @StateObject
    private var connectivity = WatchConnectionManager.shared
}
