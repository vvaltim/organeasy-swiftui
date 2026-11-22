import Foundation
import SwiftData
import WidgetKit

/// Builds the current-month summary from the entries and hands it to the widgets.
enum WidgetSync {
    static func update(with entries: [MonthlyEntry], now: Date = .now) {
        #if DEBUG
        if ShowcaseMode.isEnabled {
            let showcase = (try? ShowcaseData.container.mainContext.fetch(FetchDescriptor<MonthlyEntry>())) ?? []
            if FinanceSnapshotStore.save(makeSnapshot(showcase, now: now)) { WidgetCenter.shared.reloadAllTimelines() }
            return
        }
        #endif
        let snapshot = makeSnapshot(entries, now: now)
        if FinanceSnapshotStore.save(snapshot) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    static func makeSnapshot(_ entries: [MonthlyEntry], now: Date = .now) -> FinanceSnapshot {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let reference = monthStart.getReferenceMonth()
        let month = entries.filter { $0.referenceMonth == reference }
        let expenses = month.filter { $0.type == .expense }
        let dayCount = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30

        var daily = Array(repeating: 0.0, count: dayCount)
        for entry in expenses {
            let day = calendar.component(.day, from: entry.dueDate)
            let index = min(max(day - 1, 0), dayCount - 1)
            daily[index] += entry.amount
        }

        let upcoming = expenses
            .filter { $0.paymentDate == nil }
            .sorted { $0.dueDate < $1.dueDate }
            .prefix(6)
            .map {
                FinanceSnapshot.Bill(id: $0.id, name: $0.name, amount: $0.amount, dueDate: $0.dueDate, isIncome: false)
            }

        return FinanceSnapshot(
            monthStart: monthStart,
            income: month.filter { $0.type == .income }.map(\.amount).reduce(.zero, +),
            expense: expenses.map(\.amount).reduce(.zero, +),
            paidExpense: expenses.filter { $0.paymentDate != nil }.map(\.amount).reduce(.zero, +),
            dailyExpenses: daily,
            upcoming: Array(upcoming),
            currencyCode: Locale.current.currency?.identifier ?? "BRL",
            updatedAt: calendar.startOfDay(for: now)
        )
    }
}
