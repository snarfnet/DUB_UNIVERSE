import SwiftUI
import GoogleMobileAds

@main
struct DubUniverseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    startAdsIfConfigured()
                }
        }
    }

    private func startAdsIfConfigured() {
        guard Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") is String else {
            return
        }

        MobileAds.shared.start()
    }
}
