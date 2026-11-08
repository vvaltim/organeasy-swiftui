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

    private func chatEntries(now: Date) -> [SummaryEntry] {
        func make(_ name: String, _ amount: Double, _ type: EntryType, paid: Bool) -> SummaryEntry {
            SummaryEntry(
                id: UUID(), name: name, amount: amount, referenceMonth: now.getReferenceMonth(),
                dueDate: now, type: type, paymentDate: paid ? now : nil
            )
        }
        return [
            make("Salário", 5000, .income, paid: false),
            make("Aluguel", 1800, .expense, paid: true),
            make("Internet", 120, .expense, paid: false)
        ]
    }

    func testFactsCarryTheMonthTotals() {
        let context = SummaryChatContext(entries: chatEntries(now: .now))
        XCTAssertTrue(context.facts.contains(1920.0.getLocalCurrency()))
        XCTAssertTrue(context.facts.contains("Aluguel"))
        XCTAssertTrue(context.brief.contains(120.0.getLocalCurrency()))
    }

    func testUnknownAnswerToAmountQuestionBecomesCalculatedBrief() {
        let context = SummaryChatContext(entries: chatEntries(now: .now))
        let answer = context.answer(for: "Não sei seus gastos.", question: "qual meus gasto", toolReports: [])
        XCTAssertEqual(answer, context.brief)
    }

    func testToolResultWinsWhenModelGivesNoNumber() {
        let context = SummaryChatContext(entries: chatEntries(now: .now))
        let answer = context.answer(for: "Não encontrei.", question: "Quanto gastei com academia?", toolReports: ["Nenhum lançamento encontrado."])
        XCTAssertEqual(answer, "Nenhum lançamento encontrado.")
    }

    func testAnswersUsingFactsPassAndInventedNumbersDoNot() {
        let context = SummaryChatContext(entries: chatEntries(now: .now))
        let real = "Você gastou \(1920.0.getLocalCurrency()) neste mês."
        XCTAssertEqual(context.answer(for: real, question: "Quanto gastei?", toolReports: []), real)
        XCTAssertEqual(context.answer(for: "Você gastou R$ 777,00.", question: "Quanto gastei?", toolReports: []), context.brief)
    }

    func testAdviceQuestionKeepsTextWhenThereAreNoTips() {
        let context = SummaryChatContext(entries: [])
        let advice = "Revise suas assinaturas."
        XCTAssertEqual(context.answer(for: advice, question: "Como posso economizar?", toolReports: []), advice)
    }

    func testToolCallWrittenAsTextIsNeverShown() {
        let context = SummaryChatContext(entries: chatEntries(now: .now))
        let answer = context.answer(for: "{\"name\": \"x\"}", question: "Quanto gastei este mês?", toolReports: [])
        XCTAssertEqual(answer, context.brief)
    }

    func testGenericWordsDoNotFilterByName() {
        XCTAssertTrue(SummaryChatContext.isGenericName("Gastos"))
        XCTAssertTrue(SummaryChatContext.isGenericName("dépenses"))
        XCTAssertFalse(SummaryChatContext.isGenericName("Luz"))
    }

    func testUnknownAnswerAboutNamedBillUsesThatBill() {
        let context = SummaryChatContext(entries: chatEntries(now: .now))
        let answer = context.answer(for: "Não há registro.", question: "Quanto gastei no Aluguel este mês?", toolReports: [])
        XCTAssertTrue(answer.contains(1800.0.getLocalCurrency()))
    }

    func testOffTopicQuestionKeepsTheModelReply() {
        let context = SummaryChatContext(entries: chatEntries(now: .now))
        let reply = "Só ajudo com suas contas."
        XCTAssertEqual(context.answer(for: reply, question: "Qual é a capital da França?", toolReports: []), reply)
    }

    func testScopeUsesCurrentMonthUnlessQuestionNamesAPeriod() throws {
        let now = try XCTUnwrap(Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 5)))
        let entries = chatEntries(now: now)

        let plain = SummaryQuestionScope(question: "qual meus gasto", entries: entries, now: now)
        XCTAssertEqual(plain.month, 11)
        XCTAssertEqual(plain.year, 2026)
        XCTAssertNil(plain.name)

        let named = SummaryQuestionScope(question: "Quanto paguei de aluguel em outubro?", entries: entries, now: now)
        XCTAssertEqual(named.month, 10)
        XCTAssertEqual(named.name, "Aluguel")

        XCTAssertEqual(SummaryQuestionScope(question: "gastos em dezembro", entries: [], now: now).year, 2025)
        XCTAssertEqual(SummaryQuestionScope(question: "gastos do mês passado", entries: [], now: now).month, 10)

        let year = SummaryQuestionScope(question: "Quanto paguei de luz este ano?", entries: [], now: now)
        XCTAssertNil(year.month)
        XCTAssertEqual(year.year, 2026)
    }

    func testToolNumbersBeatTheMonthFacts() {
        let context = SummaryChatContext(entries: chatEntries(now: .now))
        let report = "Total de \(1920.0.getLocalCurrency()) em 2 lançamentos."
        let wrong = "Você gastou \(120.0.getLocalCurrency()) este mês."
        XCTAssertEqual(context.answer(for: wrong, question: "How much did I spend this month?", toolReports: [report]), report)
    }

    func testSavingQuestionUsesCalculatedTips() {
        let context = SummaryChatContext(entries: chatEntries(now: .now))
        let answer = context.answer(for: "Só ajudo com pagamentos.", question: "Como posso economizar?", toolReports: [])
        XCTAssertTrue(answer.contains("Aluguel"))
    }

    func testScopeReadsPaymentAndType() throws {
        let now = try XCTUnwrap(Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 5)))
        XCTAssertEqual(SummaryQuestionScope(question: "How much did I spend this month?", entries: [], now: now).payment, .todos)
        XCTAssertEqual(SummaryQuestionScope(question: "How much did I spend this month?", entries: [], now: now).type, .despesa)
        XCTAssertEqual(SummaryQuestionScope(question: "Quanto falta pagar?", entries: [], now: now).payment, .pendente)
        XCTAssertEqual(SummaryQuestionScope(question: "Quanto recebi?", entries: [], now: now).type, .receita)
    }

    func testUnknownBillSaysNothingFound() {
        let context = SummaryChatContext(entries: chatEntries(now: .now))
        XCTAssertEqual(
            context.answer(for: "Você gastou \(1920.0.getLocalCurrency()).", question: "Quanto gastei com academia?", toolReports: []),
            String(localized: "Nenhum lançamento encontrado.")
        )
        let scope = SummaryQuestionScope(question: "Quanto gastei no mês passado?", entries: [], now: .now)
        XCTAssertFalse(scope.isUnknownBill)
    }

    func testDueQuestionPointsToNextUnpaidBill() {
        let context = SummaryChatContext(entries: chatEntries(now: .now))
        XCTAssertTrue(context.answer(for: "Aluguel.", question: "Qual conta vence primeiro?", toolReports: []).contains("Internet"))
    }

    func testAnswerWithSeveralValuesFallsBackToTheReport() {
        let context = SummaryChatContext(entries: chatEntries(now: .now))
        let report = "Total de \(1920.0.getLocalCurrency()) e \(1800.0.getLocalCurrency())."
        let mixed = "Renda de \(1920.0.getLocalCurrency()) e \(1800.0.getLocalCurrency())."
        XCTAssertEqual(context.answer(for: mixed, question: "Me mostra minhas contas", toolReports: [report]), report)
    }
}
