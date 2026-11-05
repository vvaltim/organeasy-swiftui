import Foundation

struct SavingsSuggestion: Identifiable, Equatable {
    let id: String
    let text: String
}

/// Sugestões calculadas pelo app a partir dos gastos, sem passar pelo modelo de IA:
/// todo valor mostrado sai direto dos lançamentos.
enum SavingsAdvisor {
    private enum Constants {
        static let limit = 4
        static let frequentPurchases = 4
        static let risingRatio = 1.2
        static let stableRatio = 1.1
        static let recurringShare = 0.15
        static let reductionShare = 0.1
        static let historyMonths = 3
    }

    private struct Group {
        let name: String
        var months: [String: (total: Double, count: Int)] = [:]
    }

    static func suggestions(entries: [SummaryEntry], now: Date = .now) -> [SavingsSuggestion] {
        let calendar = Calendar.current
        let references = (0..<Constants.historyMonths).compactMap {
            calendar.date(byAdding: .month, value: -$0, to: now)?.getReferenceMonth()
        }
        guard let current = references.first else { return [] }
        let previous = Array(references.dropFirst())

        let groups = makeGroups(entries.filter { $0.type == .expense && $0.amount > .zero })
        let thisMonth = groups.filter { $0.months[current] != nil }
        let monthExpense = thisMonth.reduce(0) { $0 + ($1.months[current]?.total ?? 0) }
        guard monthExpense > .zero else { return [] }

        var result: [SavingsSuggestion] = []
        var used = Set<String>()

        func add(_ group: Group, _ text: String) {
            used.insert(group.name)
            result.append(SavingsSuggestion(id: group.name, text: text))
        }

        let income = entries
            .filter { $0.type == .income && $0.referenceMonth == current }
            .reduce(0) { $0 + $1.amount }
        if income > .zero, monthExpense > income {
            let missing = (monthExpense - income).getLocalCurrency()
            result.append(SavingsSuggestion(
                id: "negative",
                text: String(localized: "Para fechar o mês no azul, faltam \(missing) em cortes.")
            ))
        }

        let frequent = thisMonth
            .filter { ($0.months[current]?.count ?? 0) >= Constants.frequentPurchases }
            .max { total($0, current) < total($1, current) }
        if let frequent, let month = frequent.months[current] {
            let amount = month.total.getLocalCurrency()
            add(frequent, String(localized: "\(frequent.name): \(month.count) compras somam \(amount) neste mês. Comprar menos vezes é o corte mais fácil."))
        }

        func average(_ group: Group) -> Double? {
            let totals = previous.compactMap { group.months[$0]?.total }
            return totals.isEmpty ? nil : totals.reduce(0, +) / Double(totals.count)
        }

        let rising = thisMonth
            .filter { group in
                guard !used.contains(group.name), let average = average(group) else { return false }
                return total(group, current) > average * Constants.risingRatio
            }
            .max { total($0, current) - (average($0) ?? 0) < total($1, current) - (average($1) ?? 0) }
        if let rising, let average = average(rising) {
            let difference = (total(rising, current) - average).getLocalCurrency()
            add(rising, String(localized: "\(rising.name) está \(difference) acima da sua média. Veja o que mudou."))
        }

        let recurring = thisMonth
            .filter { group in
                guard !used.contains(group.name) else { return false }
                let totals = references.compactMap { group.months[$0]?.total }
                guard totals.count == references.count, let low = totals.min(), let high = totals.max() else { return false }
                return high <= low * Constants.stableRatio && high <= monthExpense * Constants.recurringShare
            }
            .max { total($0, current) < total($1, current) }
        if let recurring {
            let yearly = (total(recurring, current) * 12).getLocalCurrency()
            add(recurring, String(localized: "\(recurring.name) se repete todo mês e custa \(yearly) por ano. Veja se ainda vale a pena."))
        }

        let largest = thisMonth
            .filter { !used.contains($0.name) }
            .max { total($0, current) < total($1, current) }
        if let largest {
            let saving = (total(largest, current) * Constants.reductionShare).getLocalCurrency()
            add(largest, String(localized: "Reduzir \(largest.name) em um décimo economiza \(saving) por mês."))
        }

        return Array(result.prefix(Constants.limit))
    }

    private static func total(_ group: Group, _ month: String) -> Double {
        group.months[month]?.total ?? 0
    }

    /// Junta variações como `LANCHE 1` e `Lanche 2`, comuns em extratos de banco.
    private static func makeGroups(_ entries: [SummaryEntry]) -> [Group] {
        var groups: [String: Group] = [:]
        for entry in entries {
            let key = StatementParser.normalized(entry.name)
                .filter { !$0.isNumber }
                .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            let groupKey = key.isEmpty ? entry.name : key
            let name = entry.name.filter { !$0.isNumber }.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))

            var group = groups[groupKey] ?? Group(name: name.isEmpty ? entry.name : name)
            let month = group.months[entry.referenceMonth] ?? (0, 0)
            group.months[entry.referenceMonth] = (month.total + entry.amount, month.count + 1)
            groups[groupKey] = group
        }
        return Array(groups.values)
    }
}
