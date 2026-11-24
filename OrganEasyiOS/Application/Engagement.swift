import Combine
import StoreKit
import SwiftUI
import UserNotifications

/// Retention helpers: a daily local reminder (asked after the first saved entry, can be turned off)
/// and one App Store review request after five saved entries.
@MainActor
final class Engagement: ObservableObject {
    static let shared = Engagement()

    private enum Key {
        static let saves = "engagement.saves"
        static let asked = "engagement.askedNotifications"
        static let enabled = "engagement.remindersEnabled"
        static let reviewed = "engagement.reviewRequested"
    }

    private static let reminderID = "daily-bills-reminder"
    private let defaults = UserDefaults.standard

    @Published private(set) var remindersEnabled: Bool

    init() {
        remindersEnabled = UserDefaults.standard.bool(forKey: Key.enabled)
    }

    /// Call once per new entry saved by the user.
    func entrySaved() {
        guard !ShowcaseMode.isEnabled else { return }
        let saves = defaults.integer(forKey: Key.saves) + 1
        defaults.set(saves, forKey: Key.saves)

        if !defaults.bool(forKey: Key.asked) {
            defaults.set(true, forKey: Key.asked)
            Task { await setReminders(true) }
        }
        if saves >= 5, !defaults.bool(forKey: Key.reviewed) {
            defaults.set(true, forKey: Key.reviewed)
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                guard let scene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first(where: { $0.activationState == .foregroundActive }) else { return }
                AppStore.requestReview(in: scene)
                AppAnalytics.log("review_requested")
            }
        }
    }

    func setReminders(_ on: Bool) async {
        let center = UNUserNotificationCenter.current()
        if on {
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else {
                set(false)
                return
            }
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Lembrete das contas")
            content.body = String(localized: "Veja o que vence hoje e nos próximos dias.")
            content.sound = .default
            var time = DateComponents()
            time.hour = 9
            let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
            try? await center.add(UNNotificationRequest(identifier: Self.reminderID, content: content, trigger: trigger))
            set(true)
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [Self.reminderID])
            set(false)
        }
        AppAnalytics.log("reminders_toggle", ["enabled": on ? 1 : 0])
    }

    private func set(_ value: Bool) {
        defaults.set(value, forKey: Key.enabled)
        remindersEnabled = value
    }
}
