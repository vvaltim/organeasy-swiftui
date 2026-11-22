import FirebaseAnalytics
import FirebaseCore
import SwiftUI

/// Single entry point for Firebase Analytics. Screens and stores never call the SDK directly.
/// Every call is fire-and-forget and silently ignored until Firebase has been configured.
@MainActor
enum AppAnalytics {
    static func log(_ name: String, _ parameters: [String: Any] = [:]) {
        guard !ShowcaseMode.isEnabled, FirebaseApp.app() != nil else { return }
        var clean: [String: Any] = [:]
        for (key, value) in parameters {
            if let text = value as? String {
                clean[key] = String(text.prefix(100))
            } else {
                clean[key] = value
            }
        }
        #if DEBUG
        print("[analytics] \(name) \(clean)")
        #endif
        Analytics.logEvent(name, parameters: clean.isEmpty ? nil : clean)
    }

    static func screen(_ name: String, _ screenClass: String) {
        log(AnalyticsEventScreenView, [
            AnalyticsParameterScreenName: name,
            AnalyticsParameterScreenClass: screenClass
        ])
    }

    static func setUserProperty(_ value: String?, _ name: String) {
        guard !ShowcaseMode.isEnabled, FirebaseApp.app() != nil else { return }
        Analytics.setUserProperty(value, forName: name)
    }

    static func setPremium(_ isPremium: Bool) {
        setUserProperty(isPremium ? "true" : "false", "is_premium")
    }

    static func setLanguage() {
        setUserProperty(Locale.current.language.languageCode?.identifier ?? "und", "app_lang")
    }

    static func error(_ error: Error) -> String {
        String(String(describing: error).prefix(100))
    }
}

extension View {
    /// Logs `screen_view` each time the view appears.
    func analyticsScreen(_ name: String, class screenClass: String) -> some View {
        onAppear { AppAnalytics.screen(name, screenClass) }
    }
}
