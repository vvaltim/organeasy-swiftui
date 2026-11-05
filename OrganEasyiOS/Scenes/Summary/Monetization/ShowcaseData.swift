#if DEBUG
import SwiftData
import SwiftUI

/// Dados de exemplo do modo vitrine. Não entra em builds de release.
enum ShowcaseData {

    static let container: ModelContainer = {
        let schema = Schema([MonthlyEntry.self, RecurringEntryTemplate.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        guard let container = try? ModelContainer(for: schema, configurations: configuration) else {
            fatalError("Showcase container failed")
        }
        seed(container.mainContext)
        return container
    }()

    private static func seed(_ context: ModelContext) {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: .now)) ?? .now

        for monthsAgo in 1...5 {
            guard let month = calendar.date(byAdding: .month, value: -monthsAgo, to: startOfMonth) else { continue }
            let reference = month.getReferenceMonth()
            let income = MonthlyEntry(name: String(localized: "Salário"), amount: 5200, referenceMonth: reference, dueDate: month, type: .income)
            income.paymentDate = month
            context.insert(income)
            let expense = MonthlyEntry(name: String(localized: "Aluguel"), amount: 2600 + Double(monthsAgo % 3) * 230, referenceMonth: reference, dueDate: month, type: .expense)
            expense.paymentDate = month
            context.insert(expense)
        }

        let reference = Date.now.getReferenceMonth()
        func add(_ name: String.LocalizationValue, _ amount: Double, days: Int, type: EntryType = .expense, paid: Bool = false) {
            let due = calendar.date(byAdding: .day, value: days, to: .now) ?? .now
            let entry = MonthlyEntry(name: String(localized: name), amount: amount, referenceMonth: reference, dueDate: due, type: type)
            if paid { entry.paymentDate = due }
            context.insert(entry)
        }

        add("Salário", 5200, days: -3, type: .income, paid: true)
        add("Aluguel", 1800, days: -2, paid: true)
        add("Cartão", 640, days: -1, paid: true)
        add("Internet", 120, days: 0)
        add("Luz", 210, days: 1)
        add("Água", 85, days: 5)
        add("Academia", 99, days: 12)

        for (name, day) in [(String(localized: "Aluguel"), 5), (String(localized: "Internet"), 10), (String(localized: "Luz"), 15)] {
            context.insert(RecurringEntryTemplate(dueDay: day, enabled: true, name: name, type: .expense))
        }
        try? context.save()
    }
}

private struct ShowcaseContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        if ShowcaseMode.isEnabled || ShowcaseMode.forcesAICard {
            content.modelContainer(ShowcaseData.container)
        } else {
            content
        }
    }
}

extension View {
    func showcaseContainer() -> some View {
        modifier(ShowcaseContainerModifier())
    }
}
#endif
