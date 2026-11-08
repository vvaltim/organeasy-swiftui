import Foundation
import SwiftData

struct StatementImportPlan {
    let newTransactions: [StatementTransaction]
    let duplicateCount: Int

    var expenseTotal: Double { total(of: .expense) }
    var incomeTotal: Double { total(of: .income) }

    init(transactions: [StatementTransaction], existing: [MonthlyEntry]) {
        var known: [String: Int] = [:]
        for entry in existing {
            known[Self.key(name: entry.name, amount: entry.amount, date: entry.dueDate, type: entry.type), default: 0] += 1
        }

        var fresh: [StatementTransaction] = []
        var duplicates = 0
        for item in transactions {
            let key = Self.key(name: item.name, amount: item.amount, date: item.date, type: item.type)
            if let count = known[key], count > 0 {
                known[key] = count - 1
                duplicates += 1
            } else {
                fresh.append(item)
            }
        }
        newTransactions = fresh
        duplicateCount = duplicates
    }

    func apply(to context: ModelContext) throws {
        for item in newTransactions {
            let entry = MonthlyEntry(
                name: item.name,
                amount: item.amount,
                referenceMonth: item.date.getReferenceMonth(),
                dueDate: item.date,
                type: item.type
            )
            entry.paymentDate = item.date
            context.insert(entry)
        }
        try context.save()
    }

    private func total(of type: EntryType) -> Double {
        newTransactions.filter { $0.type == type }.reduce(0) { $0 + $1.amount }
    }

    private static func key(name: String, amount: Double, date: Date, type: EntryType) -> String {
        let day = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let cents = Int((amount * 100).rounded())
        return "\(StatementParser.normalized(name))|\(cents)|\(day.year ?? 0)-\(day.month ?? 0)-\(day.day ?? 0)|\(type.rawValue)"
    }
}
