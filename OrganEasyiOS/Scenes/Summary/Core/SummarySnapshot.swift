import Foundation

nonisolated struct SummaryEntry: Identifiable, Sendable, Hashable {
    let id: UUID
    let name: String
    let amount: Double
    let referenceMonth: String
    let dueDate: Date
    let type: EntryType
    let paymentDate: Date?

    var isPaid: Bool { paymentDate != nil }
}

extension SummaryEntry {
    init(entry: MonthlyEntry) {
        self.init(
            id: entry.id,
            name: entry.name,
            amount: entry.amount,
            referenceMonth: entry.referenceMonth,
            dueDate: entry.dueDate,
            type: entry.type,
            paymentDate: entry.paymentDate
        )
    }
}

struct SummarySnapshot {
    struct Forecast {
        let income: Double
        let expense: Double
        let paidExpense: Double

        var pendingExpense: Double { expense - paidExpense }
        var projectedBalance: Double { income - expense }
    }

    struct MonthTotals: Identifiable {
        let date: Date
        let income: Double
        let expense: Double

        var id: Date { date }
    }

    struct Comparison {
        let expense: Double
        let previousExpense: Double
        let previousMonth: Date

        var difference: Double { expense - previousExpense }
    }

    enum Constants {
        static let upcomingDays = 7
        static let upcomingVisibleLimit = 5
        static let evolutionMonths = 6
        static let topExpensesLimit = 5
    }

    let forecast: Forecast
    let expensesWithoutAmount: Int
    let upcoming: [SummaryEntry]
    let evolution: [MonthTotals]
    let comparison: Comparison?
    let topExpenses: [SummaryEntry]
    let score: Int?

    init(entries: [SummaryEntry], now: Date = .now, calendar: Calendar = .current) {
        let startOfToday = calendar.startOfDay(for: now)
        let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now)
        ) ?? now

        let monthEntries = entries.filter { $0.referenceMonth == now.getReferenceMonth() }
        let monthExpenses = monthEntries.filter { $0.type == .expense }

        forecast = Forecast(
            income: Self.total(monthEntries.filter { $0.type == .income }),
            expense: Self.total(monthExpenses),
            paidExpense: Self.total(monthExpenses.filter(\.isPaid))
        )

        expensesWithoutAmount = monthExpenses.filter { $0.amount == .zero }.count

        let upcomingLimit = calendar.date(
            byAdding: .day,
            value: Constants.upcomingDays + 1,
            to: startOfToday
        ) ?? startOfToday

        upcoming = entries
            .filter { $0.type == .expense && !$0.isPaid && $0.dueDate < upcomingLimit }
            .sorted { $0.dueDate < $1.dueDate }

        evolution = (0..<Constants.evolutionMonths).reversed().compactMap { monthsAgo in
            guard let month = calendar.date(byAdding: .month, value: -monthsAgo, to: startOfMonth) else {
                return nil
            }
            let reference = month.getReferenceMonth()
            let entriesInMonth = entries.filter { $0.referenceMonth == reference }
            return MonthTotals(
                date: month,
                income: Self.total(entriesInMonth.filter { $0.type == .income }),
                expense: Self.total(entriesInMonth.filter { $0.type == .expense })
            )
        }

        if let previous = evolution.dropLast().last, previous.expense > .zero {
            comparison = Comparison(
                expense: forecast.expense,
                previousExpense: previous.expense,
                previousMonth: previous.date
            )
        } else {
            comparison = nil
        }

        topExpenses = Array(
            monthExpenses
                .filter { $0.amount > .zero }
                .sorted { $0.amount > $1.amount }
                .prefix(Constants.topExpensesLimit)
        )

        score = Self.score(
            monthExpenses: monthExpenses,
            forecast: forecast,
            startOfToday: startOfToday
        )
    }

    private static func score(
        monthExpenses: [SummaryEntry],
        forecast: Forecast,
        startOfToday: Date
    ) -> Int? {
        guard !monthExpenses.isEmpty else { return nil }

        let onTime = monthExpenses.filter { $0.isPaid || $0.dueDate >= startOfToday }.count
        let onTimeRatio = Double(onTime) / Double(monthExpenses.count)

        let balanceRatio: Double
        if forecast.projectedBalance >= .zero {
            balanceRatio = 1
        } else if forecast.income > .zero {
            balanceRatio = max(.zero, 1 + forecast.projectedBalance / forecast.income)
        } else {
            balanceRatio = .zero
        }

        return Int((onTimeRatio * 60 + balanceRatio * 40).rounded())
    }

    private static func total(_ entries: [SummaryEntry]) -> Double {
        entries.map(\.amount).reduce(.zero, +)
    }
}
