import Combine
import Foundation

@MainActor
final class InvestorProfileStore: ObservableObject {
    static let shared = InvestorProfileStore()

    private enum Key {
        static let risk = "invest.risk"
        static let sector = "invest.sector"
        static let watchlist = "invest.watchlist"
    }

    @Published private(set) var risk: RiskProfile?
    @Published private(set) var sector: InvestmentSector?
    @Published private(set) var watchlist: Set<String>

    private let defaults: UserDefaults

    var isComplete: Bool { risk != nil && sector != nil }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        risk = defaults.string(forKey: Key.risk).flatMap(RiskProfile.init(rawValue:))
        sector = defaults.string(forKey: Key.sector).flatMap(InvestmentSector.init(rawValue:))
        watchlist = Set(defaults.stringArray(forKey: Key.watchlist) ?? [])
    }

    func save(risk: RiskProfile, sector: InvestmentSector) {
        self.risk = risk
        self.sector = sector
        defaults.set(risk.rawValue, forKey: Key.risk)
        defaults.set(sector.rawValue, forKey: Key.sector)

        Task {
            await InvestmentFirebase.save([
                "risk": risk.rawValue,
                "sector": sector.rawValue,
                "locale": Locale.current.identifier
            ])
        }
    }

    func changeSector(_ sector: InvestmentSector) {
        guard let risk else { return }
        save(risk: risk, sector: sector)
    }

    func reset() {
        risk = nil
        sector = nil
        defaults.removeObject(forKey: Key.risk)
        defaults.removeObject(forKey: Key.sector)
    }

    func toggleWatchlist(_ symbol: String) {
        let isAdded = !watchlist.contains(symbol)
        if isAdded {
            watchlist.insert(symbol)
        } else {
            watchlist.remove(symbol)
        }
        defaults.set(Array(watchlist), forKey: Key.watchlist)
        InvestmentEvent.watchlistToggled(symbol, isAdded).log()

        let saved = Array(watchlist)
        Task { await InvestmentFirebase.save(["watchlist": saved]) }
    }
}
