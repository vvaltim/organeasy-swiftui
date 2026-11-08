import Foundation
import SwiftUI

enum RiskProfile: String, CaseIterable, Identifiable, Codable, Sendable {
    case conservative
    case moderate
    case aggressive

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .conservative: "Conservador"
        case .moderate: "Moderado"
        case .aggressive: "Arriscado"
        }
    }

    var summary: LocalizedStringKey {
        switch self {
        case .conservative: "Quero proteger meu dinheiro, mesmo ganhando menos."
        case .moderate: "Aceito alguns altos e baixos para ganhar mais no longo prazo."
        case .aggressive: "Aceito perdas fortes em busca de ganhos maiores."
        }
    }

    var detail: LocalizedStringKey {
        switch self {
        case .conservative: "Prioriza empresas grandes, com lucro e negociadas todos os dias."
        case .moderate: "Equilibra tamanho, resultado, preço e movimento recente."
        case .aggressive: "Dá mais peso ao movimento recente do preço, inclusive em empresas menores."
        }
    }

    var icon: String {
        switch self {
        case .conservative: "shield.lefthalf.filled"
        case .moderate: "scale.3d"
        case .aggressive: "flame.fill"
        }
    }

    var tint: Color {
        switch self {
        case .conservative: .teal
        case .moderate: .blue
        case .aggressive: .orange
        }
    }
}

enum InvestmentSector: String, CaseIterable, Identifiable, Codable, Sendable {
    case finance
    case technology
    case energy
    case consumer
    case health
    case industry
    case realEstate
    case fixedIncome
    case crypto

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .finance: "Finanças e imóveis"
        case .technology: "Tecnologia"
        case .energy: "Energia"
        case .consumer: "Varejo e consumo"
        case .health: "Saúde"
        case .industry: "Indústria"
        case .realEstate: "Fundos na bolsa"
        case .fixedIncome: "Tesouro Direto"
        case .crypto: "Criptomoedas"
        }
    }

    var icon: String {
        switch self {
        case .finance: "building.columns.fill"
        case .technology: "cpu.fill"
        case .energy: "bolt.fill"
        case .consumer: "cart.fill"
        case .health: "cross.case.fill"
        case .industry: "gearshape.2.fill"
        case .realEstate: "building.2.fill"
        case .fixedIncome: "lock.shield.fill"
        case .crypto: "bitcoinsign.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .finance: .blue
        case .technology: .indigo
        case .energy: .yellow
        case .consumer: .pink
        case .health: .mint
        case .industry: .gray
        case .realEstate: .brown
        case .fixedIncome: .teal
        case .crypto: .orange
        }
    }

    var marketSectors: Set<String> {
        switch self {
        case .finance: ["Finance"]
        case .technology: ["Technology Services", "Electronic Technology"]
        case .energy: ["Utilities", "Energy Minerals"]
        case .consumer: ["Retail Trade", "Consumer Non-Durables", "Consumer Services", "Consumer Durables", "Distribution Services"]
        case .health: ["Health Technology", "Health Services"]
        case .industry: ["Producer Manufacturing", "Process Industries", "Non-Energy Minerals", "Transportation", "Industrial Services"]
        case .realEstate, .fixedIncome, .crypto: []
        }
    }
}

struct AssetFundamentals: Codable, Hashable, Sendable {
    var year: Int?
    var revenue: Double?
    var netIncome: Double?
    var equity: Double?
    var assets: Double?
    var roe: Double?
    var netMargin: Double?
    var debtToAssets: Double?
}

enum AssetKind: String, Hashable, Sendable {
    case stock
    case fund
    case treasury
    case crypto
}

struct InvestmentAsset: Identifiable, Hashable, Sendable {
    var id: String { symbol }

    let symbol: String
    let name: String
    let kind: AssetKind
    var marketSector: String?
    var price: Double?
    var changePercent: Double?
    var volume: Double?
    var marketCap: Double?
    var imageURL: URL?
    var fundamentals: AssetFundamentals?
    var rate: Double?
    var maturity: Date?

    var priceEarnings: Double? {
        guard let marketCap, let profit = fundamentals?.netIncome, profit > .zero else { return nil }
        return marketCap / profit
    }
}

enum AssetTrend: Sendable, Equatable {
    case breakout
    case rising
    case steady
    case falling

    init(changePercent: Double?) {
        switch changePercent ?? .zero {
        case 5...: self = .breakout
        case 1..<5: self = .rising
        case ..<(-1): self = .falling
        default: self = .steady
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .breakout: "Disparando"
        case .rising: "Em alta"
        case .steady: "Estável"
        case .falling: "Em queda"
        }
    }

    var tint: Color {
        switch self {
        case .breakout: .blue
        case .rising: .green
        case .steady: .secondary
        case .falling: .red
        }
    }
}

struct RankedAsset: Identifiable, Hashable, Sendable {
    var id: String { asset.id }

    let asset: InvestmentAsset
    let position: Int
    let score: Int

    var trend: AssetTrend { AssetTrend(changePercent: asset.changePercent) }

    static func == (lhs: RankedAsset, rhs: RankedAsset) -> Bool { lhs.id == rhs.id && lhs.score == rhs.score }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct MarketIndicators: Sendable, Equatable {
    var selic: Double?
    var inflation: Double?
    var cdi: Double?
}

struct InvestmentFilters: Equatable {
    enum Sort: String, CaseIterable, Identifiable {
        case score
        case change
        case priceEarnings
        case returnOnEquity
        case size

        var id: String { rawValue }

        var title: LocalizedStringKey {
            switch self {
            case .score: "Nota"
            case .change: "Maior alta"
            case .priceEarnings: "Menor P/L"
            case .returnOnEquity: "Maior ROE"
            case .size: "Maior empresa"
            }
        }
    }

    var sort: Sort = .score
    var onlyProfitable = false
    var onlyRising = false
    var minimumROE: Double = .zero

    var isActive: Bool { self != InvestmentFilters() }
}
