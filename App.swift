import SwiftUI
import AVFoundation
import GoogleMobileAds
import AppTrackingTransparency

@main
struct DubUniverseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var attRequested = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    configureAudioSession()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    guard !attRequested else { return }
                    attRequested = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        ATTrackingManager.requestTrackingAuthorization { _ in }
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

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        MobileAds.shared.start(completionHandler: nil)
        return true
    }
}
