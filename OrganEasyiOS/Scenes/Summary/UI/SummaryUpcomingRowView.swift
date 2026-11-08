import SwiftUI

struct SummaryUpcomingRowView: View {
    let entry: SummaryEntry
    let onMarkPaid: () -> Void

    private var daysUntilDue: Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: .now),
            to: calendar.startOfDay(for: entry.dueDate)
        ).day ?? .zero
    }

    private var dueText: LocalizedStringKey {
        switch daysUntilDue {
        case ..<0: "Atrasada desde \(entry.dueDate.formatted(.dateTime.day().month()))"
        case 0: "Vence hoje"
        case 1: "Vence amanhã"
        default: "Vence em \(daysUntilDue) dias"
        }
    }

    var body: some View {
        HStack(spacing: Size.x12.rawValue) {
            Button(action: onMarkPaid) {
                Image(systemName: SummaryIcon.circle.rawValue)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Marcar \(entry.name) como paga")

            VStack(alignment: .leading, spacing: Size.x2.rawValue) {
                Text(entry.name)
                    .font(.headline)
                Text(dueText)
                    .font(.caption)
                    .foregroundStyle(daysUntilDue < .zero ? .red : .secondary)
            }

            Spacer()

            Text(entry.amount.getLocalCurrency())
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    List {
        SummaryUpcomingRowView(
            entry: SummaryEntry(
                id: UUID(),
                name: "Internet",
                amount: 119.9,
                referenceMonth: Date.now.getReferenceMonth(),
                dueDate: .now,
                type: .expense,
                paymentDate: nil
            ),
            onMarkPaid: {}
        )
    }
}
