import XCTest
@testable import OrganEasy

final class BolsaBoardTests: XCTestCase {
    private func stock(_ symbol: String, change: Double, volume: Double = 1_000, price: Double? = 10) -> InvestmentAsset {
        InvestmentAsset(symbol: symbol, name: symbol, kind: .stock, price: price, changePercent: change, volume: volume)
    }

    func testPicksTopGainersAndLosersAmongLiquidStocks() {
        var assets = (0..<300).map { index in
            stock("S\(index)", change: Double(index % 21) - 10 + Double(index) / 1_000, volume: Double(300 - index))
        }
        assets[250] = stock("ILIQUIDA", change: 90, volume: Double(300 - 250))

        let desks = BolsaBoard.desks(from: assets)

        XCTAssertEqual(desks.count, 12)
        XCTAssertFalse(desks.contains { $0.asset.symbol == "ILIQUIDA" })

        let ups = desks.filter(\.isUp).map { $0.asset.changePercent ?? 0 }
        let downs = desks.filter { !$0.isUp }.map { $0.asset.changePercent ?? 0 }
        XCTAssertEqual(ups.count, 6)
        XCTAssertEqual(downs.count, 6)
        XCTAssertEqual(ups, ups.sorted(by: >))
        XCTAssertEqual(downs, downs.sorted())
        XCTAssertTrue(desks.prefix(6).allSatisfy(\.isUp))

        let liquid = assets.sorted { ($0.volume ?? 0) > ($1.volume ?? 0) }.prefix(200)
        XCTAssertEqual(ups.first, liquid.compactMap(\.changePercent).max())
        XCTAssertEqual(downs.first, liquid.compactMap(\.changePercent).min())
    }

    func testFlatDayHasNoDesks() {
        let assets = (0..<20).map { stock("S\($0)", change: 0) }

        XCTAssertTrue(BolsaBoard.desks(from: assets).isEmpty)
    }

    func testFewerMoversThanSlots() {
        let assets = [
            stock("A", change: 2),
            stock("B", change: 1),
            stock("C", change: -3),
            stock("D", change: 0)
        ]

        let desks = BolsaBoard.desks(from: assets)

        XCTAssertEqual(desks.map(\.asset.symbol), ["A", "B", "C"])
        XCTAssertEqual(desks.map(\.isUp), [true, true, false])
    }

    func testIgnoresAssetsWithoutPrice() {
        let assets = [
            stock("SEMPRECO", change: 50, price: nil),
            stock("QUEDA", change: -50, price: nil),
            stock("OK", change: 1)
        ]

        XCTAssertEqual(BolsaBoard.desks(from: assets).map(\.asset.symbol), ["OK"])
    }

    func testMarketClock() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Sao_Paulo"))
        func date(day: Int, hour: Int) throws -> Date {
            try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour)))
        }

        XCTAssertTrue(BolsaMarketClock.isOpen(at: try date(day: 10, hour: 11), calendar: calendar))
        XCTAssertFalse(BolsaMarketClock.isOpen(at: try date(day: 10, hour: 18), calendar: calendar))
        XCTAssertFalse(BolsaMarketClock.isOpen(at: try date(day: 14, hour: 11), calendar: calendar))
    }
}
