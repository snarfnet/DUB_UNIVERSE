import SwiftUI
import GoogleMobileAds

struct AdMobBannerView: View {
    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 320)
            let adSize = currentOrientationAnchoredAdaptiveBanner(width: width)
            BannerViewContainer(
                adUnitID: "ca-app-pub-9404799280370656/8551843827",
                adSize: adSize
            )
            .frame(width: adSize.size.width, height: adSize.size.height)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 64)
    }
}

private struct BannerViewContainer: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize

    final class Coordinator {
        var bannerView: BannerView?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        context.coordinator.bannerView = banner
        DispatchQueue.main.async {
            if let rootVC = Self.findRootViewController() {
                banner.rootViewController = rootVC
                banner.load(Request())
            }
        }
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        uiView.adSize = adSize
        if let rootVC = Self.findRootViewController() {
            uiView.rootViewController = rootVC
        }
    }

    private static func findRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            ?? UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
        return scene.keyWindow?.rootViewController
    }
}
