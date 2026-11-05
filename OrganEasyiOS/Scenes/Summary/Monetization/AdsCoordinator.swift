import Combine
import GoogleMobileAds
import SwiftUI
import UIKit
import UserMessagingPlatform

/// Só é iniciado quando a aba Resumo aparece: nenhuma outra tela carrega anúncios
/// nem pede consentimento. O formulário do Google aparece apenas onde a lei obriga.
@MainActor
final class AdsCoordinator: ObservableObject {

    static let shared = AdsCoordinator()

    @Published private(set) var canShowAds = false
    @Published private(set) var requiresPrivacyOptions = false

    private var didPrepare = false
    private var rewardedPresenter: RewardedPresenter?

    func prepare() async {
        guard !didPrepare, !ShowcaseMode.isEnabled else { return }
        didPrepare = true

        let consent = ConsentInformation.shared
        do {
            try await consent.requestConsentInfoUpdate(with: nil)
            if let controller = UIApplication.shared.topViewController {
                try await ConsentForm.loadAndPresentIfRequired(from: controller)
            }
        } catch {
            print("Failed to update ad consent: \(error)")
        }

        requiresPrivacyOptions = consent.privacyOptionsRequirementStatus == .required

        guard consent.canRequestAds else { return }
        await MobileAds.shared.start()
        canShowAds = true
    }

    func showPrivacyOptions() async {
        guard let controller = UIApplication.shared.topViewController else { return }
        try? await ConsentForm.presentPrivacyOptionsForm(from: controller)
        canShowAds = ConsentInformation.shared.canRequestAds
    }

    /// Mostra o vídeo premiado e devolve o resultado.
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

    /// Todos os anúncios são não personalizados: o app não rastreia ninguém.
    static func request() -> Request {
        let request = Request()
        let extras = Extras()
        extras.additionalParameters = ["npa": "1"]
        request.register(extras)
        return request
    }
}

// MARK: - Rewarded

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

// MARK: - Top controller

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
