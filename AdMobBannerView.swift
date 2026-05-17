import SwiftUI
import GoogleMobileAds

struct AdMobBannerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        let bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = "ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyyyyyy"  // Replace with actual AdMob banner unit ID
        bannerView.rootViewController = controller
        bannerView.load(GADRequest())

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
