import SwiftUI
import GoogleMobileAds

@main
struct DubUniverseApp: App {
    init() {
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
