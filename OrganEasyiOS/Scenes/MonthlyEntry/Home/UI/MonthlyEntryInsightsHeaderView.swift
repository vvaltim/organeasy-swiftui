import Charts
import SwiftUI

/// Home header: big month balance, income/expense cards, daily spending bars with the
/// average line, and a proportional "where the money goes" bar.
struct MonthlyEntryInsightsHeaderView: View {
    let entries: [MonthlyEntry]
    let monthDate: Date

    private var currencyCode: String { Locale.current.currency?.identifier ?? "BRL" }
    private var expenses: [MonthlyEntry] { entries.filter { $0.type == .expense } }
    private var income: Double { entries.filter { $0.type == .income }.map(\.amount).reduce(.zero, +) }
    private var expense: Double { expenses.map(\.amount).reduce(.zero, +) }
    private var paid: Double { expenses.filter { $0.paymentDate != nil }.map(\.amount).reduce(.zero, +) }
    private var paidPercent: Int { expense > .zero ? Int((paid / expense * 100).rounded()) : .zero }

    var body: some View {
        VStack(alignment: .leading, spacing: Size.x16.rawValue) {
            balance
            cards
            if expense > .zero {
                DailySpendingChart(entries: expenses, monthDate: monthDate, currencyCode: currencyCode)
                    .frame(height: 150)
                SpendingBreakdownBar(entries: expenses)
            }
        }
        .padding(.vertical, Size.x8.rawValue)
    }

    private var balance: some View {
        VStack(alignment: .leading, spacing: Size.x4.rawValue) {
            HStack(spacing: Size.x8.rawValue) {
                Text("Saldo do mês")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(monthDate.getDateFormatted(with: .MMMMyyyy))
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, Size.x8.rawValue)
                    .padding(.vertical, Size.x2.rawValue)
                    .background(.quaternary, in: .capsule)
            }
            BigAmountText(value: income - expense, currencyCode: currencyCode, size: 46, showsSign: true)
                .foregroundStyle(income - expense < 0 ? Color.red : Color.primary)
        }
        .accessibilityElement(children: .combine)
    }

    private var cards: some View {
        HStack(spacing: Size.x12.rawValue) {
            card(title: "Receitas", value: income, symbol: "arrow.down.left", tint: .green, footer: nil)
            card(
                title: "Despesas",
                value: expense,
                symbol: "arrow.up.right",
                tint: .red,
                footer: expense > .zero ? "\(paidPercent)% pago" : nil
            )
        }
    }

    private func card(title: LocalizedStringKey, value: Double, symbol: String, tint: Color, footer: LocalizedStringKey?) -> some View {
        HStack(spacing: Size.x8.rawValue) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.15), in: .rect(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value, format: .currency(code: currencyCode))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let footer {
                    Text(footer)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: .zero)
        }
        .padding(Size.x12.rawValue)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Daily chart

struct DailySpendingChart: View {
    let entries: [MonthlyEntry]
    let monthDate: Date
    let currencyCode: String

    private struct Day: Identifiable {
        let day: Int
        let date: Date
        let amount: Double
        let isFuture: Bool
        var id: Int { day }
    }

    private var days: [Day] {
        let calendar = Calendar.current
        let count = calendar.range(of: .day, in: .month, for: monthDate)?.count ?? 30
        var totals = Array(repeating: 0.0, count: count)
        for entry in entries {
            let index = min(max(calendar.component(.day, from: entry.dueDate) - 1, 0), count - 1)
            totals[index] += entry.amount
        }
        let today = Date.now
        return totals.enumerated().map { index, amount in
            let date = calendar.date(byAdding: .day, value: index, to: monthDate) ?? monthDate
            return Day(day: index + 1, date: date, amount: amount, isFuture: calendar.startOfDay(for: date) > calendar.startOfDay(for: today))
        }
    }

    var body: some View {
        let days = days
        let total = days.map(\.amount).reduce(.zero, +)
        let average = total / Double(max(days.count, 1))
        let peak = days.map(\.amount).max() ?? .zero

        VStack(alignment: .leading, spacing: Size.x8.rawValue) {
            HStack {
                Text("Gastos por dia")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("média \(average.formatted(.currency(code: currencyCode).precision(.fractionLength(0))))/dia")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Chart {
                ForEach(days) { day in
                    BarMark(
                        x: .value("Dia", day.date, unit: .day),
                        yStart: .value("Base", 0.0),
                        yEnd: .value("Valor", peak),
                        width: .ratio(0.62)
                    )
                    .foregroundStyle(Color.primary.opacity(0.05))
                    .cornerRadius(3)

                    if day.amount > .zero {
                        BarMark(
                            x: .value("Dia", day.date, unit: .day),
                            yStart: .value("Base", 0.0),
                            yEnd: .value("Valor", day.amount),
                            width: .ratio(0.62)
                        )
                        .foregroundStyle(day.isFuture ? Color.primary.opacity(0.3) : Color.primary)
                        .cornerRadius(3)
                    }
                }
                RuleMark(y: .value("Média", average))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(Color.secondary)
            }
            .chartXScale(domain: monthDate...(Calendar.current.date(byAdding: .day, value: days.count, to: monthDate) ?? monthDate))
            .chartXAxis {
                AxisMarks(values: [1, 8, 15, 22, 29].compactMap { index in days.first { $0.day == index }?.date.addingTimeInterval(43_200) }) { _ in
                    AxisValueLabel(format: .dateTime.day(), anchor: .top)
                }
            }
            .chartYAxis(.hidden)
            .accessibilityLabel("Gastos por dia")
        }
    }
}

// MARK: - Breakdown bar

struct SpendingBreakdownBar: View {
    let entries: [MonthlyEntry]

    private static let palette: [Color] = [.orange, .pink, .purple, .blue]

    private struct Slice: Identifiable {
        let name: String
        let amount: Double
        let color: Color
        var id: String { name }
    }

    private var slices: [Slice] {
        var totals: [String: Double] = [:]
        for entry in entries where entry.amount > .zero {
            totals[entry.name, default: .zero] += entry.amount
        }
        let sorted = totals.sorted { $0.value > $1.value }
        var result = sorted.prefix(4).enumerated().map { index, item in
            Slice(name: item.key, amount: item.value, color: Self.palette[index])
        }
        let rest = sorted.dropFirst(4).map(\.value).reduce(.zero, +)
        if rest > .zero {
            result.append(Slice(name: String(localized: "Outros"), amount: rest, color: .gray))
        }
        return result
    }

    var body: some View {
        let slices = slices
        let total = slices.map(\.amount).reduce(.zero, +)
        if total > .zero {
            VStack(alignment: .leading, spacing: Size.x8.rawValue) {
                GeometryReader { proxy in
                    let spacing: CGFloat = 4
                    let available = proxy.size.width - spacing * CGFloat(max(slices.count - 1, 0))
                    HStack(spacing: spacing) {
                        ForEach(slices) { slice in
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(slice.color.gradient)
                                .frame(width: max(available * slice.amount / total, 6))
                        }
                    }
                }
                .frame(height: 26)

                FlowLegend(items: slices.map { ($0.name, $0.color, $0.amount / total) })
            }
            .accessibilityElement(children: .combine)
        }
    }
}

private struct FlowLegend: View {
    let items: [(String, Color, Double)]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)], spacing: Size.x4.rawValue) {
            ForEach(items, id: \.0) { name, color, share in
                HStack(spacing: Size.x4.rawValue) {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text(name)
                        .font(.caption)
                        .lineLimit(1)
                    Text(share, format: .percent.precision(.fractionLength(0)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
    }
}
