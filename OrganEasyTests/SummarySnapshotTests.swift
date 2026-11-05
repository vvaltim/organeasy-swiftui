import XCTest
@testable import OrganEasy

@MainActor
final class SummarySnapshotTests: XCTestCase {
    private let calendar = Calendar.current

    private func entry(
        _ name: String,
        _ amount: Double,
        days: Int,
        type: EntryType = .expense,
        paid: Bool = false,
        now: Date
    ) -> SummaryEntry {
        let due = calendar.date(byAdding: .day, value: days, to: now)!
        return SummaryEntry(
            id: UUID(), name: name, amount: amount,
            referenceMonth: now.getReferenceMonth(), dueDate: due, type: type,
            paymentDate: paid ? now : nil
        )
    }

    func testForecastSeparatesPaidAndPending() {
        let now = Date.now
        let snapshot = SummarySnapshot(entries: [
            entry("Salário", 5000, days: 0, type: .income, now: now),
            entry("Aluguel", 1800, days: 0, paid: true, now: now),
            entry("Internet", 120, days: 0, now: now)
        ], now: now)

        XCTAssertEqual(snapshot.forecast.paidExpense, 1800)
        XCTAssertEqual(snapshot.forecast.pendingExpense, 120)
        XCTAssertEqual(snapshot.forecast.projectedBalance, 3080)
    }

    func testUpcomingExcludesPaidAndFarAwayBills() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 10, hour: 12))!
        let snapshot = SummarySnapshot(entries: [
            entry("Paga", 10, days: 1, paid: true, now: now),
            entry("Atrasada", 10, days: -1, now: now),
            entry("Limite", 10, days: 7, now: now),
            entry("Longe", 10, days: 9, now: now)
        ], now: now)

        XCTAssertEqual(snapshot.upcoming.map(\.name), ["Atrasada", "Limite"])
    }

    func testBillsWithoutAmountAreCounted() {
        let now = Date.now
        let snapshot = SummarySnapshot(entries: [entry("Condomínio", 0, days: 1, now: now)], now: now)
        XCTAssertEqual(snapshot.expensesWithoutAmount, 1)
    }

    func testScoreRewardsOnTimeBillsAndPositiveBalance() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 10, hour: 12))!
        let good = SummarySnapshot(entries: [
            entry("Salário", 1000, days: 0, type: .income, now: now),
            entry("Luz", 100, days: 2, now: now)
        ], now: now)
        XCTAssertEqual(good.score, 100)

        let late = SummarySnapshot(entries: [
            entry("Salário", 1000, days: 0, type: .income, now: now),
            entry("Luz", 100, days: -2, now: now),
            entry("Água", 100, days: 2, now: now)
        ], now: now)
        XCTAssertEqual(late.score, 70)
    }

    func testScoreIsNilWithoutExpenses() {
        XCTAssertNil(SummarySnapshot(entries: [], now: .now).score)
    }

    func testToolFiltersAndComputesTotals() {
        let now = Date.now
        let entries = [
            entry("Conta de Água", 80, days: 0, now: now),
            entry("Água da casa", 20, days: 0, paid: true, now: now),
            entry("Salário", 5000, days: 0, type: .income, now: now)
        ]
        let pending = EntryLookupTool.filter(entries, with: .init(
            name: "agua", year: nil, month: nil, type: .despesa, payment: .pendente
        ))
        XCTAssertEqual(pending.map(\.name), ["Conta de Água"])
        XCTAssertTrue(EntryLookupTool.report(entries: pending).contains("80"))
        XCTAssertFalse(EntryLookupTool.report(entries: []).isEmpty)
    }

    func testGuardRejectsInventedNumbersAndCleansMarkdown() {
        let report = "Total de R$ 514,00 em 4 lançamentos. Maiores: Luz: R$ 210,00."
        XCTAssertEqual(
            SummaryAnswerGuard.verified("Faltam **R$ 514,00**.", question: "Quanto falta?", reports: [report]),
            "Faltam R$ 514,00."
        )
        XCTAssertEqual(
            SummaryAnswerGuard.verified("São 514 reais.", question: "Quanto falta?", reports: [report]),
            "São 514 reais."
        )
        XCTAssertNil(SummaryAnswerGuard.verified("Te sobran 96,00 €.", question: "¿Cuánto?", reports: [report]))
        XCTAssertNil(SummaryAnswerGuard.verified("Faltam R$ 300.", question: "Quanto?", reports: []))
        XCTAssertEqual(SummaryAnswerGuard.verified("Olá!", question: "Oi", reports: []), "Olá!")
    }
}

@MainActor
final class PromotionClockTests: XCTestCase {
    override func setUp() {
        PromotionClock.reset()
    }

    override func tearDown() {
        PromotionClock.reset()
    }

    func testStartDateNeverRestarts() {
        let first = PromotionClock.startIfNeeded(now: Date(timeIntervalSince1970: 1_000))
        let second = PromotionClock.startIfNeeded(now: Date(timeIntervalSince1970: 9_000))
        XCTAssertEqual(first, second)
        XCTAssertEqual(PromotionClock.duration, 86_400)
    }
}
