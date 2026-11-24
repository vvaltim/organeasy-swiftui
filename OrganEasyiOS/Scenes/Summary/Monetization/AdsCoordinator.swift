import Combine
import GoogleMobileAds
import SwiftUI
import UIKit

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

    private var interstitial: InterstitialAd?
    private var appOpen: AppOpenAd?
    private var appOpenLoadedAt = Date.distantPast
    private var isLoadingInterstitial = false
    private var isLoadingAppOpen = false
    private var interstitialRetry: TimeInterval = 30
    private var appOpenRetry: TimeInterval = 30
    private var lastFullScreen = Date.distantPast
    private let launchedAt = Date()
    private var completedActions = 0
    private var isFullScreenShowing = false
    private var suppressNextAppOpen = false
    private var didHandleLaunch = false
    private var backgroundedAt: Date?
    private var sessionCount = 0

    var isBannerEnabled: Bool { canShowAds && AdsConfig.bannerEnabled }

    private var isEligible: Bool {
        canShowAds && !PurchaseStore.shared.isAdsRemoved && !PurchaseStore.shared.isPremium && !ShowcaseMode.isEnabled
    }

    func prepare() async {
        guard !didPrepare, !ShowcaseMode.isEnabled else { return }
        didPrepare = true

        if Self.isInEurope() {
            adsUnavailableHere = true
            return
        }

        sessionCount = UserDefaults.standard.integer(forKey: "ads.sessionCount") + 1
        UserDefaults.standard.set(sessionCount, forKey: "ads.sessionCount")

        await PurchaseStore.shared.refreshEntitlements()
        MobileAds.shared.requestConfiguration.maxAdContentRating = .parentalGuidance
        await MobileAds.shared.start()
        canShowAds = true
        preloadAll()
    }

    func preloadAll() {
        guard isEligible else { return }
        loadInterstitial()
        if AdsConfig.appOpenEnabled { loadAppOpen() }
    }

    /// Uses only the device region. No consent form or Google location check.
    private static func isInEurope() -> Bool {
        guard let region = Locale.current.region?.identifier.uppercased() else { return false }
        return europeanRegions.contains(region)
    }

    func presentRewarded() async -> RewardedOutcome {
        guard canShowAds, let controller = UIApplication.shared.topViewController else {
            return .unavailable
        }

        do {
            let ad = try await RewardedAd.load(with: AdUnits.rewarded, request: Self.request())
            let presenter = RewardedPresenter(ad: ad)
            rewardedPresenter = presenter
            isFullScreenShowing = true
            let outcome = await presenter.present(from: controller)
            isFullScreenShowing = false
            lastFullScreen = .now
            rewardedPresenter = nil
            return outcome
        } catch {
            print("Failed to load rewarded ad: \(error)")
            return .unavailable
        }
    }

    // MARK: - Interstitial

    /// Call after a natural pause (an entry was saved). Every Nth call, with cooldown, shows an interstitial.
    func actionCompleted() {
        guard isEligible else { return }
        completedActions += 1
        guard completedActions >= AdsConfig.interstitialEvery,
              Date.now.timeIntervalSince(launchedAt) > 60,
              Date.now.timeIntervalSince(lastFullScreen) >= AdsConfig.interstitialCooldown,
              !isFullScreenShowing,
              let ad = interstitial else {
            if interstitial == nil { loadInterstitial() }
            return
        }
        completedActions = 0
        interstitial = nil
        // Wait for the form sheet to finish dismissing before presenting.
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.8))
            guard let controller = UIApplication.shared.topViewController, !self.isFullScreenShowing else {
                self.interstitial = ad
                return
            }
            let delegate = FullScreenDelegate(format: "interstitial", placement: "entry_saved", coordinator: self)
            ad.fullScreenContentDelegate = delegate
            self.activeDelegates.insert(delegate)
            self.isFullScreenShowing = true
            ad.present(from: controller)
        }
    }

    private func loadInterstitial() {
        guard isEligible, interstitial == nil, !isLoadingInterstitial else { return }
        isLoadingInterstitial = true
        Task { @MainActor in
            defer { self.isLoadingInterstitial = false }
            do {
                let ad = try await InterstitialAd.load(with: AdUnits.interstitial, request: Self.request())
                self.interstitial = ad
                self.interstitialRetry = 30
                AppAnalytics.log("ad_show", ["format": "interstitial", "placement": "loaded"])
            } catch {
                AppAnalytics.log("ad_fail", ["format": "interstitial", "error": AppAnalytics.error(error)])
                let delay = self.interstitialRetry
                self.interstitialRetry = min(120, delay * 2)
                try? await Task.sleep(for: .seconds(delay))
                self.loadInterstitial()
            }
        }
    }

    // MARK: - App open

    private func loadAppOpen() {
        guard isEligible, AdsConfig.appOpenEnabled, !isLoadingAppOpen else { return }
        if appOpen != nil, Date.now.timeIntervalSince(appOpenLoadedAt) < 4 * 3600 { return }
        isLoadingAppOpen = true
        Task { @MainActor in
            defer { self.isLoadingAppOpen = false }
            do {
                let ad = try await AppOpenAd.load(with: AdUnits.appOpen, request: Self.request())
                self.appOpen = ad
                self.appOpenLoadedAt = .now
                self.appOpenRetry = 30
            } catch {
                AppAnalytics.log("ad_fail", ["format": "app_open", "error": AppAnalytics.error(error)])
                let delay = self.appOpenRetry
                self.appOpenRetry = min(120, delay * 2)
                try? await Task.sleep(for: .seconds(delay))
                self.loadAppOpen()
            }
        }
    }

    /// Called when the scene changes phase. App open never shows on the first session.
    func scenePhaseChanged(active: Bool) async {
        guard didPrepare else { return }
        if !active {
            backgroundedAt = .now
            return
        }
        defer { backgroundedAt = nil }

        if !didHandleLaunch {
            didHandleLaunch = true
            guard sessionCount >= 2 else { return }
            // At launch, show only if it loads within 4 seconds.
            for _ in 0..<8 where appOpen == nil && isEligible {
                loadAppOpen()
                try? await Task.sleep(for: .milliseconds(500))
            }
            showAppOpen()
            return
        }

        guard let away = backgroundedAt, Date.now.timeIntervalSince(away) >= 30 else { return }
        if suppressNextAppOpen {
            suppressNextAppOpen = false
            return
        }
        showAppOpen()
    }

    private func showAppOpen() {
        guard isEligible, AdsConfig.appOpenEnabled, !isFullScreenShowing,
              Date.now.timeIntervalSince(lastFullScreen) >= AdsConfig.appOpenCooldown,
              let ad = appOpen,
              Date.now.timeIntervalSince(appOpenLoadedAt) < 4 * 3600,
              let controller = UIApplication.shared.topViewController else {
            loadAppOpen()
            return
        }
        appOpen = nil
        let delegate = FullScreenDelegate(format: "app_open", placement: "resume", coordinator: self)
        ad.fullScreenContentDelegate = delegate
        activeDelegates.insert(delegate)
        isFullScreenShowing = true
        ad.present(from: controller)
    }

    fileprivate var activeDelegates: Set<FullScreenDelegate> = []

    fileprivate func fullScreenFinished(_ delegate: FullScreenDelegate) {
        activeDelegates.remove(delegate)
        isFullScreenShowing = false
        lastFullScreen = .now
        preloadAll()
    }

    fileprivate func adWasClicked() {
        suppressNextAppOpen = true
    }

    // MARK: - Revenue

    static func logImpression(_ value: AdValue, format: String, placement: String) {
        AppAnalytics.log("ad_impression", [
            "value": value.value.doubleValue,
            "currency": value.currencyCode,
            "ad_platform": "admob",
            "ad_format": format,
            "placement": placement,
            "precision": value.precision.rawValue,
        ])
    }

    static func request() -> Request {
        let request = Request()
        let extras = Extras()
        extras.additionalParameters = ["npa": "1"]
        request.register(extras)
        return request
    }
}

@MainActor
final class FullScreenDelegate: NSObject, FullScreenContentDelegate {
    private let format: String
    private let placement: String
    private unowned let coordinator: AdsCoordinator

    init(format: String, placement: String, coordinator: AdsCoordinator) {
        self.format = format
        self.placement = placement
        self.coordinator = coordinator
    }

    nonisolated func ad(_ ad: any FullScreenPresentingAd, didRecordPaidEventWith adValue: AdValue) {
        Task { @MainActor in
            AdsCoordinator.logImpression(adValue, format: self.format, placement: self.placement)
        }
    }

    nonisolated func adDidRecordClick(_ ad: any FullScreenPresentingAd) {
        Task { @MainActor in self.coordinator.adWasClicked() }
    }

    nonisolated func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        Task { @MainActor in
            AppAnalytics.log("ad_show", ["format": self.format, "placement": "dismissed"])
            self.coordinator.fullScreenFinished(self)
        }
    }

    nonisolated func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        Task { @MainActor in
            AppAnalytics.log("ad_fail", ["format": self.format, "error": AppAnalytics.error(error)])
            self.coordinator.fullScreenFinished(self)
        }
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

    nonisolated func ad(_ ad: any FullScreenPresentingAd, didRecordPaidEventWith adValue: AdValue) {
        Task { @MainActor in
            AdsCoordinator.logImpression(adValue, format: "rewarded", placement: "assistant")
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
