import Foundation

nonisolated struct BolsaDesk: Identifiable, Hashable, Sendable {
    let asset: InvestmentAsset
    let isUp: Bool

    var id: String { asset.symbol }
}

nonisolated enum BolsaBoard {
    static func desks(from assets: [InvestmentAsset], perSide: Int = 6, liquidPool: Int = 200) -> [BolsaDesk] {
        let liquid = assets
            .filter { $0.price != nil && $0.changePercent != nil }
            .sorted { ($0.volume ?? 0) > ($1.volume ?? 0) }
            .prefix(liquidPool)

        let gainers = liquid
            .filter { ($0.changePercent ?? 0) > 0 }
            .sorted { ($0.changePercent ?? 0) > ($1.changePercent ?? 0) }
            .prefix(perSide)
            .map { BolsaDesk(asset: $0, isUp: true) }

        let losers = liquid
            .filter { ($0.changePercent ?? 0) < 0 }
            .sorted { ($0.changePercent ?? 0) < ($1.changePercent ?? 0) }
            .prefix(perSide)
            .map { BolsaDesk(asset: $0, isUp: false) }

        return gainers + losers
    }
}

nonisolated enum BolsaMarketClock {
    static var saoPaulo: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo") ?? .current
        return calendar
    }

    static func isOpen(at date: Date = .now, calendar: Calendar = saoPaulo) -> Bool {
        guard !calendar.isDateInWeekend(date) else { return false }
        let hour = calendar.component(.hour, from: date)
        return (10..<17).contains(hour)
    }
}
