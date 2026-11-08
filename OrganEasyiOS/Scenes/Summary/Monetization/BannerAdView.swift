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
        banner.load(AdsCoordinator.request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
