import Combine
import GoogleMobileAds
import SwiftUI
import UIKit
import UserMessagingPlatform

/// Ads run only outside Europe. In the EEA, the UK and Switzerland the app
/// shows no ads and no consent form. The app does not track users, so there is
/// no ATT prompt, and every ad request is non-personalized.
@MainActor
final class AdsCoordinator: ObservableObject {
    static let shared = AdsCoordinator()

    private static let europeanRegions: Set<String> = [
        "AT", "BE", "BG", "CH", "CY", "CZ", "DE", "DK", "EE", "ES", "FI", "FR", "GB",
        "GR", "HR", "HU", "IE", "IS", "IT", "LI", "LT", "LU", "LV", "MT", "NL", "NO",
        "PL", "PT", "RO", "SE", "SI", "SK",
    ]

    @Published private(set) var canShowAds = false
    /// True in Europe, where the app has no ads and nothing to remove.
    @Published private(set) var adsUnavailableHere = false

    private var didPrepare = false
    private var rewardedPresenter: RewardedPresenter?

    func prepare() async {
        guard !didPrepare, !ShowcaseMode.isEnabled else { return }
        didPrepare = true

        if await Self.isInEurope() {
            adsUnavailableHere = true
            return
        }

        MobileAds.shared.requestConfiguration.maxAdContentRating = .parentalGuidance
        await MobileAds.shared.start()
        canShowAds = true
    }

    /// Uses the device region and Google's location check. The form is never shown.
    private static func isInEurope() async -> Bool {
        if let region = Locale.current.region?.identifier.uppercased(),
           europeanRegions.contains(region) {
            return true
        }
        let consent = ConsentInformation.shared
        do {
            try await consent.requestConsentInfoUpdate(with: nil)
        } catch {
            print("Failed to check ad region: \(error)")
            return false
        }
        return consent.consentStatus == .required || consent.consentStatus == .obtained
    }

    func presentRewarded() async -> RewardedOutcome {
        guard canShowAds, let controller = UIApplication.shared.topViewController else {
            return .unavailable
        }

        do {
            let ad = try await RewardedAd.load(with: AdUnits.rewarded, request: Self.request())
            let presenter = RewardedPresenter(ad: ad)
            rewardedPresenter = presenter
            let outcome = await presenter.present(from: controller)
            rewardedPresenter = nil
            return outcome
        } catch {
            print("Failed to load rewarded ad: \(error)")
            return .unavailable
        }
    }

    static func request() -> Request {
        let request = Request()
        let extras = Extras()
        extras.additionalParameters = ["npa": "1"]
        request.register(extras)
        return request
    }
}

enum RewardedOutcome {
    case earned
    case dismissed
    case unavailable
}

@MainActor
private final class RewardedPresenter: NSObject, FullScreenContentDelegate {
    private let ad: RewardedAd
    private var didEarn = false
    private var continuation: CheckedContinuation<RewardedOutcome, Never>?

    init(ad: RewardedAd) {
        self.ad = ad
    }

    func present(from controller: UIViewController) async -> RewardedOutcome {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            ad.fullScreenContentDelegate = self
            ad.present(from: controller) { [weak self] in
                self?.didEarn = true
            }
        }
    }

    nonisolated func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        Task { @MainActor in
            self.finish(self.didEarn ? .earned : .dismissed)
        }
    }

    nonisolated func ad(
        _ ad: any FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: any Error
    ) {
        Task { @MainActor in
            self.finish(.unavailable)
        }
    }

    private func finish(_ outcome: RewardedOutcome) {
        continuation?.resume(returning: outcome)
        continuation = nil
    }
}

extension UIApplication {
    var topViewController: UIViewController? {
        let scene = connectedScenes.compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive }
            ?? connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var controller = scene?.keyWindow?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
}
