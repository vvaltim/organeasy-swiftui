import SwiftUI

struct MonthlyEntrySummaryHeaderView: View {
    let income: Double
    let expense: Double

    private var balance: Double { income - expense }

    var body: some View {
        HStack(alignment: .top, spacing: Size.x16.rawValue) {
            MonthlyEntrySummaryItemView(title: "Entradas", value: income, color: .green)
            Divider()
                .frame(height: Size.x48.rawValue)
            MonthlyEntrySummaryItemView(title: "Saídas", value: expense, color: .red)
            Divider()
                .frame(height: Size.x48.rawValue)
            MonthlyEntrySummaryItemView(title: "Saldo", value: balance, color: balanceColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Resumo: Entradas, Saídas e Restante")
    }

    private var balanceColor: Color {
        if balance > 0 { return .green }
        if balance < 0 { return .red }
        return .secondary
    }
}

// MARK: - Preview

#Preview("HomeSummaryHeaderView") {
    VStack(spacing: Size.x16.rawValue) {
        MonthlyEntrySummaryHeaderView(income: 2500, expense: 1750)
        MonthlyEntrySummaryHeaderView(income: 1200.75, expense: 1800.20)
        MonthlyEntrySummaryHeaderView(income: 1000, expense: 1000)
    }
    .padding()
}
