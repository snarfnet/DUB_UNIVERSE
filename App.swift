import SwiftUI
import GoogleMobileAds

@main
struct DubUniverseApp: App {
    init() {
        MobileAds.shared.start { _ in
            print("AdMob SDK initialized")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
