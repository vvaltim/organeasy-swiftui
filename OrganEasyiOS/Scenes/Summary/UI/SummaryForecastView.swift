import SwiftUI

struct SummaryForecastView: View {
    let forecast: SummarySnapshot.Forecast
    let expensesWithoutAmount: Int

    private var paidFraction: Double {
        guard forecast.expense > .zero else { return .zero }
        return forecast.paidExpense / forecast.expense
    }

    private var balanceColor: Color {
        if forecast.projectedBalance > .zero { return .green }
        if forecast.projectedBalance < .zero { return .red }
        return .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Size.x12.rawValue) {
            VStack(alignment: .leading, spacing: Size.x4.rawValue) {
                Text("Deve sobrar neste mês")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(forecast.projectedBalance.getLocalCurrency())
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(balanceColor)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }

            ProgressView(value: paidFraction)

            HStack(alignment: .top, spacing: Size.x16.rawValue) {
                MonthlyEntrySummaryItemView(title: "Já pago", value: forecast.paidExpense, color: .primary)
                MonthlyEntrySummaryItemView(title: "Falta pagar", value: forecast.pendingExpense, color: .primary)
            }

            if expensesWithoutAmount > .zero {
                Label(
                    "^[\(expensesWithoutAmount) conta](inflect: true) sem valor fora da previsão",
                    systemImage: SummaryIcon.warning.rawValue
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Size.x4.rawValue)
    }
}

#Preview {
    List {
        SummaryForecastView(
            forecast: .init(income: 5000, expense: 3200, paidExpense: 1200),
            expensesWithoutAmount: 2
        )
    }
}
