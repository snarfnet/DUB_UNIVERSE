import SwiftUI
import AVFoundation
import GoogleMobileAds

@main
struct DubUniverseApp: App {
    init() {
        configureAudioSession()
        DispatchQueue.main.async {
            MobileAds.shared.start { _ in
                print("AdMob SDK initialized")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
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
