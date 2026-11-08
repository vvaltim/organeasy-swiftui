import FirebaseAnalytics
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Foundation

@MainActor
enum InvestmentFirebase {
    private static var isStarted = false

    static func start() {
        guard !isStarted, !ShowcaseMode.isEnabled else { return }
        isStarted = true
        FirebaseApp.configure()
        Analytics.setConsent([
            .adStorage: .denied,
            .adUserData: .denied,
            .adPersonalization: .denied,
            .analyticsStorage: .granted
        ])
    }

    static func save(_ fields: [String: Any]) async {
        guard isStarted else { return }
        do {
            let user: User
            if let current = Auth.auth().currentUser {
                user = current
            } else {
                user = try await Auth.auth().signInAnonymously().user
            }
            var document = fields
            document["updatedAt"] = FieldValue.serverTimestamp()
            try await Firestore.firestore().collection("users").document(user.uid).setData(document, merge: true)
        } catch {
            print("Failed to save investor profile: \(error)")
        }
    }

    static func loadWatchlist() async -> Set<String>? {
        guard isStarted, let user = Auth.auth().currentUser else { return nil }
        let snapshot = try? await Firestore.firestore().collection("users").document(user.uid).getDocument()
        return (snapshot?.data()?["watchlist"] as? [String]).map(Set.init)
    }
}

enum InvestmentEvent {
    case onboardingStarted
    case riskSelected(RiskProfile)
    case sectorSelected(InvestmentSector)
    case onboardingCompleted(RiskProfile, InvestmentSector)
    case listViewed(InvestmentSector, Int)
    case assetOpened(String, Int)
    case lockedTapped(String)
    case paywallViewed(String)
    case purchaseStarted(String)
    case purchaseCompleted(String)
    case filterChanged(String)
    case watchlistToggled(String, Bool)

    @MainActor
    func log() {
        guard !ShowcaseMode.isEnabled, FirebaseApp.app() != nil else { return }
        Analytics.logEvent(name, parameters: parameters)

        if case .onboardingCompleted(let risk, let sector) = self {
            Analytics.setUserProperty(risk.rawValue, forName: "risk_profile")
            Analytics.setUserProperty(sector.rawValue, forName: "sector")
        }
    }

    private var name: String {
        switch self {
        case .onboardingStarted: "invest_onboarding_start"
        case .riskSelected: "invest_risk_selected"
        case .sectorSelected: "invest_sector_selected"
        case .onboardingCompleted: "invest_onboarding_complete"
        case .listViewed: "invest_list_view"
        case .assetOpened: "invest_asset_open"
        case .lockedTapped: "invest_locked_tap"
        case .paywallViewed: "invest_paywall_view"
        case .purchaseStarted: "invest_purchase_start"
        case .purchaseCompleted: "invest_purchase_complete"
        case .filterChanged: "invest_filter_change"
        case .watchlistToggled: "invest_watchlist_toggle"
        }
    }

    private var parameters: [String: Any] {
        switch self {
        case .onboardingStarted: [:]
        case .riskSelected(let risk): ["risk": risk.rawValue]
        case .sectorSelected(let sector): ["sector": sector.rawValue]
        case .onboardingCompleted(let risk, let sector): ["risk": risk.rawValue, "sector": sector.rawValue]
        case .listViewed(let sector, let count): ["sector": sector.rawValue, "count": count]
        case .assetOpened(let symbol, let position): ["symbol": symbol, "position": position]
        case .lockedTapped(let source), .paywallViewed(let source): ["source": source]
        case .purchaseStarted(let product), .purchaseCompleted(let product): ["product": product]
        case .filterChanged(let filter): ["filter": filter]
        case .watchlistToggled(let symbol, let isAdded): ["symbol": symbol, "added": isAdded ? 1 : 0]
        }
    }
}
