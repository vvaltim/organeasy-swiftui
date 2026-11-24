import FirebaseCore
import FirebaseRemoteConfig
import Foundation

/// Ad frequency knobs. Built-in defaults always work; Remote Config only overrides them
/// and a failed fetch never affects the app.
@MainActor
enum AdsConfig {
    private static let defaults: [String: NSObject] = [
        "ads_interstitial_every": 2 as NSNumber,
        "ads_interstitial_cooldown_s": 60 as NSNumber,
        "ads_app_open_enabled": true as NSNumber,
        "ads_app_open_cooldown_s": 180 as NSNumber,
        "ads_banner_enabled": true as NSNumber,
    ]

    static func fetch() {
        guard !ShowcaseMode.isEnabled, FirebaseApp.app() != nil else { return }
        let remote = RemoteConfig.remoteConfig()
        remote.setDefaults(defaults)
        remote.fetchAndActivate { _, _ in }
    }

    private static func number(_ key: String) -> Int {
        if FirebaseApp.app() != nil {
            return RemoteConfig.remoteConfig().configValue(forKey: key).numberValue.intValue
        }
        return (defaults[key] as? NSNumber)?.intValue ?? 0
    }

    static var interstitialEvery: Int { max(1, number("ads_interstitial_every")) }
    static var interstitialCooldown: TimeInterval { TimeInterval(max(10, number("ads_interstitial_cooldown_s"))) }
    static var appOpenEnabled: Bool { number("ads_app_open_enabled") != 0 }
    static var appOpenCooldown: TimeInterval { TimeInterval(max(30, number("ads_app_open_cooldown_s"))) }
    static var bannerEnabled: Bool { number("ads_banner_enabled") != 0 }
}
