import Combine
import Foundation

@MainActor
final class SummaryAIAccess: ObservableObject {
    static let shared = SummaryAIAccess()

    private enum Constants {
        static let unlockDuration: TimeInterval = 30 * 60
    }

    @Published private(set) var unlockedUntil: Date?
    @Published private(set) var isLoadingVideo = false
    @Published private(set) var wasVideoDismissed = false

    var isUnlocked: Bool {
        if ShowcaseMode.isEnabled { return true }
        guard let unlockedUntil else { return false }
        return unlockedUntil > .now
    }

    func perform(hasAccess: Bool, action: @escaping @MainActor () -> Void) {
        guard !hasAccess else {
            action()
            return
        }

        Task {
            await watchVideo()
            if isUnlocked { action() }
        }
    }

    func watchVideo() async {
        guard !isLoadingVideo else { return }
        isLoadingVideo = true
        wasVideoDismissed = false
        defer { isLoadingVideo = false }

        switch await AdsCoordinator.shared.presentRewarded() {
        case .earned:
            AppAnalytics.log("ad_show", ["format": "rewarded", "placement": "assistant_unlock"])
            AppAnalytics.log("ad_reward", ["placement": "assistant_unlock"])
            unlockedUntil = Date.now.addingTimeInterval(Constants.unlockDuration)
        case .unavailable:
            AppAnalytics.log("ad_fail", ["format": "rewarded", "error": "unavailable"])
            unlockedUntil = Date.now.addingTimeInterval(Constants.unlockDuration)
        case .dismissed:
            AppAnalytics.log("ad_show", ["format": "rewarded", "placement": "assistant_unlock"])
            AppAnalytics.log("ad_offer_declined", ["placement": "assistant_unlock"])
            wasVideoDismissed = true
        }
    }
}
