import GoogleMobileAds
import SwiftUI

struct BannerAdView: View {
    var body: some View {
        GeometryReader { proxy in
            let size = currentOrientationAnchoredAdaptiveBanner(width: proxy.size.width)
            BannerContainer(size: size)
                .frame(width: size.size.width, height: size.size.height)
                .frame(maxWidth: .infinity)
        }
        .frame(height: Constants.defaultHeight)
    }

    private enum Constants {
        static let defaultHeight: CGFloat = 60
    }
}

private struct BannerContainer: UIViewRepresentable {
    let size: AdSize

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: size)
        banner.adUnitID = AdUnits.banner
        banner.rootViewController = UIApplication.shared.topViewController
        banner.delegate = context.coordinator
        banner.load(AdsCoordinator.request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, BannerViewDelegate {
        func bannerView(_ bannerView: BannerView, didRecordPaidEventWith adValue: AdValue) {
            Task { @MainActor in AdsCoordinator.logImpression(adValue, format: "banner", placement: "bottom") }
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            Task { @MainActor in AppAnalytics.log("ad_show", ["format": "banner", "placement": "bottom"]) }
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
            Task { @MainActor in AppAnalytics.log("ad_fail", ["format": "banner", "error": AppAnalytics.error(error)]) }
        }
    }
}
