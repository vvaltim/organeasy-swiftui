import Charts
import SwiftUI
import WidgetKit

// MARK: - Timeline

struct FinanceEntry: TimelineEntry {
    let date: Date
    let snapshot: FinanceSnapshot
    let hasData: Bool
}

struct FinanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> FinanceEntry {
        FinanceEntry(date: .now, snapshot: .sample, hasData: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (FinanceEntry) -> Void) {
        if context.isPreview, FinanceSnapshotStore.load() == nil {
            completion(placeholder(in: context))
        } else {
            completion(currentEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FinanceEntry>) -> Void) {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) ?? .now.addingTimeInterval(86_400)
        completion(Timeline(entries: [currentEntry()], policy: .after(tomorrow)))
    }

    private func currentEntry() -> FinanceEntry {
        guard let snapshot = FinanceSnapshotStore.load() else {
            return FinanceEntry(date: .now, snapshot: .empty, hasData: false)
        }
        let calendar = Calendar.current
        let isCurrentMonth = calendar.isDate(snapshot.monthStart, equalTo: .now, toGranularity: .month)
        return FinanceEntry(date: .now, snapshot: isCurrentMonth ? snapshot : .empty, hasData: isCurrentMonth)
    }
}

// MARK: - Helpers

private enum WidgetLink {
    static let home = URL(string: "organeasy://home")!
    static let newEntry = URL(string: "organeasy://nova")!
}

private extension FinanceSnapshot {
    var monthName: String {
        monthStart.formatted(.dateTime.month(.wide)).capitalized
    }
}

private func dueText(_ date: Date) -> Text {
    let calendar = Calendar.current
    let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: .now), to: calendar.startOfDay(for: date)).day ?? .zero
    switch days {
    case ..<0: return Text("Atrasada").foregroundStyle(.red)
    case 0: return Text("Hoje").foregroundStyle(.orange)
    case 1: return Text("Amanhã").foregroundStyle(.orange)
    default: return Text(date, format: .dateTime.day().month(.abbreviated)).foregroundStyle(.secondary)
    }
}

private struct PaidProgressBar: View {
    let ratio: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule().fill(Color.green.gradient)
                    .frame(width: max(proxy.size.width * ratio, ratio > .zero ? 6 : .zero))
            }
        }
        .frame(height: 6)
    }
}

private struct EmptyWidgetView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Abra o OrganEasy para ver seu mês")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Balance (small + lock screen)

struct BalanceWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FinanceEntry

    private var snapshot: FinanceSnapshot { entry.snapshot }

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: snapshot.paidRatio) {
                Image(systemName: "checkmark")
            } currentValueLabel: {
                Text(snapshot.paidRatio, format: .percent.precision(.fractionLength(0)))
            }
            .gaugeStyle(.accessoryCircularCapacity)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text("Saldo de \(snapshot.monthName)")
                    .font(.caption2)
                    .widgetAccentable()
                Text(snapshot.balance, format: .currency(code: snapshot.currencyCode))
                    .font(.headline)
                    .monospacedDigit()
                Text("Falta pagar \(snapshot.pendingExpense.formatted(.currency(code: snapshot.currencyCode)))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .accessoryInline:
            Text("Saldo \(snapshot.balance.formatted(.currency(code: snapshot.currencyCode)))")
        default:
            small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "wallet.bifold.fill")
                    .foregroundStyle(.tint)
                Text(snapshot.monthName)
                    .textCase(.uppercase)
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(.secondary)

            Text("Saldo do mês")
                .font(.caption2)
                .foregroundStyle(.secondary)
            BigAmountText(value: snapshot.balance, currencyCode: snapshot.currencyCode, size: 26, showsSign: true)
                .foregroundStyle(snapshot.balance < 0 ? Color.red : Color.primary)

            Spacer(minLength: .zero)

            HStack(spacing: 4) {
                Text("+" + snapshot.income.formatted(.number.notation(.compactName)))
                    .foregroundStyle(.green)
                Text("|").foregroundStyle(.quaternary)
                Text("−" + snapshot.expense.formatted(.number.notation(.compactName)))
                    .foregroundStyle(.red)
            }
            .font(.caption.weight(.semibold))
            .monospacedDigit()

            PaidProgressBar(ratio: snapshot.paidRatio)
            Text("\(Int((snapshot.paidRatio * 100).rounded()))% das contas pagas")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay { if !entry.hasData { EmptyWidgetView().background(.background) } }
    }
}

struct BalanceWidget: Widget {
    let kind = "BalanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FinanceProvider()) { entry in
            BalanceWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(WidgetLink.home)
        }
        .configurationDisplayName("Saldo do mês")
        .description("Receitas, despesas e quanto das contas já foi pago.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Upcoming bills (medium / large + lock screen)

struct UpcomingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FinanceEntry

    private var snapshot: FinanceSnapshot { entry.snapshot }
    private var billLimit: Int { family == .systemLarge ? 6 : 3 }

    var body: some View {
        if family == .accessoryRectangular {
            lockScreen
        } else if !entry.hasData {
            EmptyWidgetView()
        } else if family == .systemLarge {
            VStack(alignment: .leading, spacing: 12) {
                summary
                    .frame(maxWidth: .infinity, maxHeight: 130, alignment: .leading)
                Divider()
                bills
            }
        } else {
            HStack(alignment: .top, spacing: 14) {
                summary
                    .frame(width: 118, alignment: .leading)
                bills
            }
        }
    }

    private var lockScreen: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Próxima conta")
                .font(.caption2)
                .widgetAccentable()
            if let bill = snapshot.upcoming.first {
                Text(bill.name)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(bill.amount, format: .currency(code: snapshot.currencyCode))
                    Text("·")
                    dueText(bill.dueDate)
                }
                .font(.caption2)
            } else {
                Text("Tudo pago 🎉")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Saldo de \(snapshot.monthName)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            BigAmountText(value: snapshot.balance, currencyCode: snapshot.currencyCode, size: 26, showsSign: true)
                .foregroundStyle(snapshot.balance < 0 ? Color.red : Color.primary)
            Text("Falta pagar")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            Text(snapshot.pendingExpense, format: .currency(code: snapshot.currencyCode))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: .zero)
            Link(destination: WidgetLink.newEntry) {
                Label("Nova", systemImage: "plus")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.tint.opacity(0.18), in: .capsule)
            }
        }
    }

    private var bills: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Próximas contas")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            if snapshot.upcoming.isEmpty {
                Spacer(minLength: .zero)
                Label("Tudo pago neste mês", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                Spacer(minLength: .zero)
            } else {
                ForEach(snapshot.upcoming.prefix(billLimit)) { bill in
                    HStack(spacing: 8) {
                        EntryIconTile(name: bill.name, isIncome: false, size: 26)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(bill.name)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            dueText(bill.dueDate)
                                .font(.system(size: 10))
                        }
                        Spacer(minLength: 4)
                        Text(bill.amount, format: .currency(code: snapshot.currencyCode))
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                Spacer(minLength: .zero)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct UpcomingWidget: Widget {
    let kind = "UpcomingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FinanceProvider()) { entry in
            UpcomingWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(WidgetLink.home)
        }
        .configurationDisplayName("Próximas contas")
        .description("O que vence primeiro e quanto ainda falta pagar.")
        .supportedFamilies([.systemMedium, .systemLarge, .accessoryRectangular])
    }
}

// MARK: - Spending chart (medium)

struct SpendingWidgetView: View {
    let entry: FinanceEntry

    private var snapshot: FinanceSnapshot { entry.snapshot }

    var body: some View {
        if !entry.hasData {
            EmptyWidgetView()
        } else {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gastos de \(snapshot.monthName)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    BigAmountText(value: snapshot.expense, currencyCode: snapshot.currencyCode, size: 24)
                    Spacer(minLength: .zero)
                    Text("Média por dia")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(snapshot.averagePerDay, format: .currency(code: snapshot.currencyCode))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
                .frame(width: 122, alignment: .leading)

                chart
            }
        }
    }

    private var chart: some View {
        let today = Calendar.current.component(.day, from: .now)
        let peak = snapshot.dailyExpenses.max() ?? .zero
        let calendar = Calendar.current
        func date(_ index: Int) -> Date { calendar.date(byAdding: .day, value: index, to: snapshot.monthStart) ?? snapshot.monthStart }
        let count = snapshot.dailyExpenses.count
        return Chart {
            ForEach(Array(snapshot.dailyExpenses.enumerated()), id: \.offset) { index, amount in
                BarMark(x: .value("Dia", date(index), unit: .day), yStart: .value("Base", 0.0), yEnd: .value("Valor", peak), width: .ratio(0.6))
                    .foregroundStyle(Color.primary.opacity(0.06))
                    .cornerRadius(2)
                if amount > .zero {
                    BarMark(x: .value("Dia", date(index), unit: .day), yStart: .value("Base", 0.0), yEnd: .value("Valor", amount), width: .ratio(0.6))
                        .foregroundStyle(index + 1 > today ? Color.primary.opacity(0.3) : Color.primary)
                        .cornerRadius(2)
                }
            }
            RuleMark(y: .value("Média", snapshot.averagePerDay))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .foregroundStyle(Color.secondary)
        }
        .chartXScale(domain: snapshot.monthStart...date(count))
        .chartXAxis {
            AxisMarks(values: [0, 9, 19].map { date($0).addingTimeInterval(43_200) }) { _ in
                AxisValueLabel(format: .dateTime.day(), anchor: .top)
                    .font(.system(size: 9))
            }
        }
        .chartYAxis(.hidden)
    }
}

struct SpendingWidget: Widget {
    let kind = "SpendingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FinanceProvider()) { entry in
            SpendingWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(WidgetLink.home)
        }
        .configurationDisplayName("Gastos do mês")
        .description("Gráfico dos gastos por dia com a média do mês.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Bundle

@main
struct OrganEasyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        BalanceWidget()
        UpcomingWidget()
        SpendingWidget()
    }
}

#Preview(as: .systemSmall) {
    BalanceWidget()
} timeline: {
    FinanceEntry(date: .now, snapshot: .sample, hasData: true)
}

#Preview(as: .systemMedium) {
    UpcomingWidget()
} timeline: {
    FinanceEntry(date: .now, snapshot: .sample, hasData: true)
}

#Preview(as: .systemMedium) {
    SpendingWidget()
} timeline: {
    FinanceEntry(date: .now, snapshot: .sample, hasData: true)
}
