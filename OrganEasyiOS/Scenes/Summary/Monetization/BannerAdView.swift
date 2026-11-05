import GoogleMobileAds
import SwiftUI

/// Banner adaptativo fixo acima da barra de abas. Só existe dentro da aba Resumo.
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
