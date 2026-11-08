import Foundation

/// Nota de 0 a 100 dentro do setor, calculada só com dados públicos.
/// Compara os ativos entre si: não prevê retorno nem indica compra.
enum InvestmentRanking {
    private struct Weights {
        let size: Double
        let liquidity: Double
        let quality: Double
        let value: Double
        let momentum: Double
    }

    private static func weights(for risk: RiskProfile) -> Weights {
        switch risk {
        case .conservative: Weights(size: 0.4, liquidity: 0.2, quality: 0.3, value: 0.1, momentum: 0)
        case .moderate: Weights(size: 0.2, liquidity: 0.15, quality: 0.3, value: 0.2, momentum: 0.15)
        case .aggressive: Weights(size: 0, liquidity: 0.15, quality: 0.15, value: 0.1, momentum: 0.6)
        }
    }

    static func rank(_ assets: [InvestmentAsset], risk: RiskProfile) -> [RankedAsset] {
        let candidates = eligible(assets, risk: risk)
        guard !candidates.isEmpty else { return [] }

        let weights = weights(for: risk)
        let size = percentiles(candidates) { $0.marketCap }
        let liquidity = percentiles(candidates) { $0.volume }
        let quality = percentiles(candidates) { $0.fundamentals?.roe }
        let value = percentiles(candidates) { $0.priceEarnings.map { -$0 } }
        let momentum = percentiles(candidates) { $0.changePercent }
        let rate = percentiles(candidates) { $0.rate }

        let scored = candidates.map { asset -> (InvestmentAsset, Int) in
            if asset.kind == .treasury {
                return (asset, treasuryScore(asset, rate: rate[asset.id] ?? 0.5, risk: risk))
            }

            let parts: [(Double?, Double)] = [
                (size[asset.id], weights.size),
                (liquidity[asset.id], weights.liquidity),
                (quality[asset.id], weights.quality),
                (value[asset.id], weights.value),
                (momentum[asset.id], weights.momentum)
            ]
            // Ativo sem um dado não perde nota: o peso daquele dado é redistribuído.
            let available = parts.compactMap { part in part.0.map { ($0, part.1) } }
            let total = available.reduce(0) { $0 + $1.1 }
            guard total > .zero else { return (asset, 50) }
            let score = available.reduce(0) { $0 + $1.0 * $1.1 } / total
            return (asset, Int((score * 100).rounded()))
        }

        return scored
            .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : ($0.0.marketCap ?? 0) > ($1.0.marketCap ?? 0) }
            .enumerated()
            .map { RankedAsset(asset: $0.element.0, position: $0.offset + 1, score: $0.element.1) }
    }

    /// Perfil conservador não vê empresa com prejuízo ou ativo sem liquidez.
    private static func eligible(_ assets: [InvestmentAsset], risk: RiskProfile) -> [InvestmentAsset] {
        let priced = assets.filter { ($0.price ?? 0) > .zero }
        guard risk == .conservative else { return priced }
        return priced.filter { asset in
            if let profit = asset.fundamentals?.netIncome, profit <= .zero { return false }
            if asset.kind == .treasury || asset.kind == .crypto { return true }
            return (asset.volume ?? 0) > .zero
        }
    }

    /// Título pós-fixado curto é o menos sensível a oscilações antes do vencimento.
    private static func treasuryScore(_ asset: InvestmentAsset, rate: Double, risk: RiskProfile) -> Int {
        let isFloating = asset.name.localizedCaseInsensitiveContains("Selic")
        let stability = isFloating ? 1.0 : 0.4
        let score: Double
        switch risk {
        case .conservative: score = stability * 0.7 + rate * 0.3
        case .moderate: score = stability * 0.4 + rate * 0.6
        case .aggressive: score = rate
        }
        return Int((score * 100).rounded())
    }

    /// Posição relativa de cada ativo, de 0 a 1. Valores ausentes ficam de fora.
    private static func percentiles(
        _ assets: [InvestmentAsset],
        value: (InvestmentAsset) -> Double?
    ) -> [String: Double] {
        let known = assets.compactMap { asset in value(asset).map { (asset.id, $0) } }
        guard known.count > 1 else { return Dictionary(known.map { ($0.0, 0.5) }, uniquingKeysWith: { first, _ in first }) }

        let sorted = known.sorted { $0.1 < $1.1 }
        var result: [String: Double] = [:]
        for (index, item) in sorted.enumerated() {
            result[item.0] = Double(index) / Double(sorted.count - 1)
        }
        return result
    }

    // MARK: - Filtros

    static func apply(_ filters: InvestmentFilters, to ranked: [RankedAsset]) -> [RankedAsset] {
        let filtered = ranked.filter { item in
            if filters.onlyProfitable, (item.asset.fundamentals?.netIncome ?? 0) <= .zero { return false }
            if filters.onlyRising, (item.asset.changePercent ?? 0) <= .zero { return false }
            if filters.minimumROE > .zero, (item.asset.fundamentals?.roe ?? -.infinity) < filters.minimumROE { return false }
            return true
        }

        switch filters.sort {
        case .score:
            return filtered
        case .change:
            return filtered.sorted { ($0.asset.changePercent ?? -.infinity) > ($1.asset.changePercent ?? -.infinity) }
        case .priceEarnings:
            return filtered.sorted { ($0.asset.priceEarnings ?? .infinity) < ($1.asset.priceEarnings ?? .infinity) }
        case .returnOnEquity:
            return filtered.sorted { ($0.asset.fundamentals?.roe ?? -.infinity) > ($1.asset.fundamentals?.roe ?? -.infinity) }
        case .size:
            return filtered.sorted { ($0.asset.marketCap ?? 0) > ($1.asset.marketCap ?? 0) }
        }
    }
}
