import SwiftUI

struct MonthlyEntrySummaryItemView: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Size.x4.rawValue) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value.getLocalCurrency())
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("HomeSummaryHeaderView") {
    VStack(spacing: Size.x16.rawValue) {
        MonthlyEntrySummaryItemView(title: "Entradas", value: 1234.56, color: .red)
        MonthlyEntrySummaryItemView(title: "Saídas", value: 1234.56, color: .green)
    }
    .padding()
}
