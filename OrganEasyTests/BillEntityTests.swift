import SwiftData
import XCTest
@testable import OrganEasy

@MainActor
final class BillEntityTests: XCTestCase {
    private var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([MonthlyEntry.self, RecurringEntryTemplate.self])
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        context = ModelContext(container)
    }

    private func add(_ name: String, _ amount: Double, days: Int, paid: Bool = false) {
        let date = Calendar.current.date(byAdding: .day, value: days, to: .now)!
        let entry = MonthlyEntry(name: name, amount: amount, referenceMonth: date.getReferenceMonth(), dueDate: date, type: .expense)
        entry.paymentDate = paid ? date : nil
        context.insert(entry)
    }

    func testPendingBillsComeFirstInDueOrder() throws {
        add("Aluguel", 1800, days: -3, paid: true)
        add("Luz", 210, days: 5)
        add("Internet", 120, days: 1)

        XCTAssertEqual(try BillStore.bills(context: context).map(\.name), ["Internet", "Luz", "Aluguel"])
    }

    func testSearchFindsByNameAndGenericWordsReturnEverything() throws {
        add("Conta de luz", 210, days: 5)
        add("Internet", 120, days: 1)

        XCTAssertEqual(try BillStore.bills(matching: "luz", context: context).map(\.name), ["Conta de luz"])
        XCTAssertEqual(try BillStore.bills(matching: "contas", context: context).count, 2)
        XCTAssertTrue(try BillStore.bills(matching: "academia", context: context).isEmpty)
    }

    func testAnswerCarriesAmountAndDueDate() throws {
        add("Luz", 210, days: 5)

        let answer = FindBillsIntent.answer(for: try BillStore.bills(context: context))

        XCTAssertTrue(answer.contains("Luz"))
        XCTAssertTrue(answer.contains(210.0.getLocalCurrency()))
        XCTAssertEqual(FindBillsIntent.answer(for: []), String(localized: "Nenhum lançamento encontrado."))
    }
}
