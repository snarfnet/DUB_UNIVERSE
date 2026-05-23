import SwiftUI
import AVFoundation
import GoogleMobileAds

@main
struct DubUniverseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    configureAudioSession()
                    MobileAds.shared.start { _ in
                        print("AdMob SDK initialized")
                    }
                }
        }
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
}
