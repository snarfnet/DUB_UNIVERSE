import SwiftUI
import GoogleMobileAds

struct AdMobBannerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        guard Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") is String else {
            return controller
        }

        MobileAds.shared.start()

        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = "ca-app-pub-9404799280370656/8551843827"
        bannerView.rootViewController = controller
        bannerView.load(Request())

        controller.view.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
            bannerView.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor)
        ])

        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
