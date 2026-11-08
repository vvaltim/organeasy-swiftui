import XCTest
@testable import OrganEasy

final class InvestmentRankingTests: XCTestCase {
    private func stock(
        _ symbol: String,
        cap: Double,
        volume: Double = 1_000,
        change: Double = 0,
        roe: Double? = nil,
        profit: Double? = nil
    ) -> InvestmentAsset {
        var asset = InvestmentAsset(symbol: symbol, name: symbol, kind: .stock, price: 10, changePercent: change, volume: volume, marketCap: cap)
        if roe != nil || profit != nil {
            asset.fundamentals = AssetFundamentals(netIncome: profit, roe: roe)
        }
        return asset
    }

    func testConservativePrefersLargeProfitableAndAggressivePrefersMomentum() {
        let assets = [
            stock("GRANDE", cap: 900, volume: 900, change: -0.5, roe: 25, profit: 100),
            stock("MEDIA", cap: 300, volume: 300, change: 1, roe: 12, profit: 20),
            stock("FOGUETE", cap: 10, volume: 50, change: 18, roe: 3, profit: 1)
        ]

        XCTAssertEqual(InvestmentRanking.rank(assets, risk: .conservative).first?.asset.symbol, "GRANDE")
        XCTAssertEqual(InvestmentRanking.rank(assets, risk: .aggressive).first?.asset.symbol, "FOGUETE")
    }

    func testConservativeHidesCompaniesWithLosses() {
        let assets = [stock("LUCRO", cap: 100, profit: 10), stock("PREJUIZO", cap: 500, profit: -10)]

        let conservative = InvestmentRanking.rank(assets, risk: .conservative).map(\.asset.symbol)
        let aggressive = InvestmentRanking.rank(assets, risk: .aggressive).map(\.asset.symbol)

        XCTAssertEqual(conservative, ["LUCRO"])
        XCTAssertTrue(aggressive.contains("PREJUIZO"))
    }

    func testPositionsAreSequentialAndScoresStayInRange() {
        let assets = (1...20).map { stock("A\($0)", cap: Double($0), volume: Double(21 - $0), change: Double($0 % 7) - 3) }
        let ranked = InvestmentRanking.rank(assets, risk: .moderate)

        XCTAssertEqual(ranked.map(\.position), Array(1...20))
        XCTAssertTrue(ranked.allSatisfy { (0...100).contains($0.score) })
    }

    func testSingleAssetAndMissingDataDoNotBreakRanking() {
        let lone = InvestmentAsset(symbol: "X", name: "X", kind: .fund, price: 1)
        XCTAssertEqual(InvestmentRanking.rank([lone], risk: .moderate).first?.position, 1)
        XCTAssertTrue(InvestmentRanking.rank([], risk: .moderate).isEmpty)
    }

    func testAssetsWithoutPriceAreDropped() {
        var unpriced = stock("SEMPRECO", cap: 10)
        unpriced.price = nil
        XCTAssertEqual(InvestmentRanking.rank([unpriced, stock("OK", cap: 1)], risk: .moderate).map(\.asset.symbol), ["OK"])
    }

    func testPriceEarningsNeedsProfit() {
        XCTAssertEqual(stock("A", cap: 100, profit: 10).priceEarnings, 10)
        XCTAssertNil(stock("B", cap: 100, profit: -5).priceEarnings)
    }

    func testFiltersAndSorting() {
        let ranked = InvestmentRanking.rank([
            stock("A", cap: 300, change: 2, roe: 30, profit: 10),
            stock("B", cap: 200, change: -1, roe: 10, profit: 10),
            stock("C", cap: 100, change: 5, roe: 2, profit: -1)
        ], risk: .moderate)

        var filters = InvestmentFilters()
        filters.onlyProfitable = true
        XCTAssertEqual(Set(InvestmentRanking.apply(filters, to: ranked).map(\.asset.symbol)), ["A", "B"])

        filters = InvestmentFilters()
        filters.onlyRising = true
        XCTAssertEqual(Set(InvestmentRanking.apply(filters, to: ranked).map(\.asset.symbol)), ["A", "C"])

        filters = InvestmentFilters()
        filters.minimumROE = 20
        XCTAssertEqual(InvestmentRanking.apply(filters, to: ranked).map(\.asset.symbol), ["A"])

        filters = InvestmentFilters()
        filters.sort = .change
        XCTAssertEqual(InvestmentRanking.apply(filters, to: ranked).first?.asset.symbol, "C")
    }

    func testTrendThresholds() {
        XCTAssertEqual(AssetTrend(changePercent: 6), .breakout)
        XCTAssertEqual(AssetTrend(changePercent: 2), .rising)
        XCTAssertEqual(AssetTrend(changePercent: 0.2), .steady)
        XCTAssertEqual(AssetTrend(changePercent: -3), .falling)
        XCTAssertEqual(AssetTrend(changePercent: nil), .steady)
    }

    func testTreasuryRankingFavorsFloatingRateForConservatives() {
        let selic = InvestmentAsset(symbol: "Tesouro Selic 2029", name: "Tesouro Selic", kind: .treasury, price: 100, rate: 0.1)
        let fixed = InvestmentAsset(symbol: "Tesouro Prefixado 2031", name: "Tesouro Prefixado", kind: .treasury, price: 100, rate: 15)

        XCTAssertEqual(InvestmentRanking.rank([selic, fixed], risk: .conservative).first?.asset.name, "Tesouro Selic")
        XCTAssertEqual(InvestmentRanking.rank([selic, fixed], risk: .aggressive).first?.asset.name, "Tesouro Prefixado")
    }
}

final class MarketParserTests: XCTestCase {
    func testMarketResponseSkipsFractionalShares() throws {
        let json = #"{"stocks":[{"stock":"WEGE3","name":"WEG S.A.","close":40.5,"change":1.2,"volume":100,"market_cap":1000,"sector":"Producer Manufacturing"},{"stock":"WEGE3F","close":40.5}]}"#
        let assets = try MarketParser.market(from: Data(json.utf8), kind: .stock)

        XCTAssertEqual(assets.map(\.symbol), ["WEGE3"])
        XCTAssertEqual(assets[0].marketSector, "Producer Manufacturing")
        XCTAssertEqual(assets[0].price, 40.5)
    }

    func testTreasuryAndCryptoAndFundamentals() throws {
        let treasury = try MarketParser.treasury(from: Data(#"{"titles":[{"name":"Tesouro Selic","maturity":"2029-03-01","rate":0.06,"price":20226.6}]}"#.utf8))
        XCTAssertEqual(treasury[0].symbol, "Tesouro Selic 2029")
        XCTAssertEqual(InvestmentFormat.treasuryRate(treasury[0]).hasPrefix("Selic + "), true)

        let crypto = try MarketParser.crypto(from: Data(#"[{"symbol":"btc","name":"Bitcoin","current_price":100.0,"market_cap":10.0,"total_volume":1.0,"price_change_percentage_24h":-2.0}]"#.utf8))
        XCTAssertEqual(crypto[0].symbol, "BTC")
        XCTAssertEqual(crypto[0].changePercent, -2)

        let companies = try MarketParser.fundamentals(from: Data(#"{"companies":{"WEGE3":{"year":2025,"roe":36.5,"netIncome":10}}}"#.utf8))
        XCTAssertEqual(companies["WEGE3"]?.roe, 36.5)

        XCTAssertEqual(MarketParser.latestSeriesValue(from: Data(#"[{"data":"x","valor":"13.75"}]"#.utf8)), 13.75)
    }
}

@MainActor
final class InvestorProfileStoreTests: XCTestCase {
    func testProfileSurvivesRestartAndResets() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let store = InvestorProfileStore(defaults: defaults)
        XCTAssertFalse(store.isComplete)

        store.save(risk: .moderate, sector: .energy)

        let reopened = InvestorProfileStore(defaults: defaults)
        XCTAssertEqual(reopened.risk, .moderate)
        XCTAssertEqual(reopened.sector, .energy)
        XCTAssertTrue(reopened.isComplete)

        reopened.reset()
        XCTAssertFalse(InvestorProfileStore(defaults: defaults).isComplete)
    }
}
