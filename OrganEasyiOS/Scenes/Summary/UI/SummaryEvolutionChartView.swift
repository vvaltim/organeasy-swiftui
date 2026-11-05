import Charts
import SwiftUI

struct SummaryEvolutionChartView: View {
    let months: [SummarySnapshot.MonthTotals]

    private enum Constants {
        static let chartHeight: CGFloat = 180
    }

    private let incomeLabel = String(localized: "Entradas")
    private let expenseLabel = String(localized: "Saídas")

    var body: some View {
        Chart(months) { month in
            BarMark(
                x: .value("Mês", month.date, unit: .month),
                y: .value("Valor", month.income)
            )
            .position(by: .value("Tipo", incomeLabel))
            .foregroundStyle(by: .value("Tipo", incomeLabel))

            BarMark(
                x: .value("Mês", month.date, unit: .month),
                y: .value("Valor", month.expense)
            )
            .position(by: .value("Tipo", expenseLabel))
            .foregroundStyle(by: .value("Tipo", expenseLabel))
        }
        .chartForegroundStyleScale([incomeLabel: Color.green, expenseLabel: Color.red])
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
            }
        }
        .frame(height: Constants.chartHeight)
        .padding(.vertical, Size.x4.rawValue)
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let months = (0..<6).reversed().compactMap { monthsAgo -> SummarySnapshot.MonthTotals? in
        guard let date = calendar.date(byAdding: .month, value: -monthsAgo, to: .now) else { return nil }
        return .init(date: date, income: 5000, expense: Double(2500 + monthsAgo * 300))
    }

    return List {
        SummaryEvolutionChartView(months: months)
    }
}
