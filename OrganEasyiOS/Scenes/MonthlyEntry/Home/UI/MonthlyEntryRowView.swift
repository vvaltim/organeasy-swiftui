import SwiftUI

struct MonthlyEntryRowView: View {
    let entry: MonthlyEntry
    let onEdit: () -> Void
    let onTogglePaid: () -> Void

    private var isPaid: Bool { entry.paymentDate != nil }
    private var isIncome: Bool { entry.type == .income }
    private var currencyCode: String { Locale.current.currency?.identifier ?? "BRL" }

    private var daysUntilDue: Int {
        let calendar = Calendar.current
        return calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: .now),
            to: calendar.startOfDay(for: entry.dueDate)
        ).day ?? .zero
    }

    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: Size.x12.rawValue) {
                EntryIconTile(name: entry.name, isIncome: isIncome)
                    .overlay(alignment: .bottomTrailing) {
                        if isPaid {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13, weight: .bold))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .green)
                                .offset(x: 4, y: 4)
                        }
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    status
                        .font(.caption)
                }

                Spacer(minLength: Size.x8.rawValue)

                Text((isIncome ? 1 : -1) * entry.amount, format: .currency(code: currencyCode).sign(strategy: .always()))
                    .font(.body.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(isIncome ? Color.green : Color.primary)
                    .strikethrough(isPaid && !isIncome, color: .secondary)
            }
            .opacity(isPaid ? 0.55 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(entry.paymentDate == nil ? "Mark Paid" : "Unmark") {
                onTogglePaid()
            }.tint(.blue)
        }
    }

    @ViewBuilder
    private var status: some View {
        if isPaid {
            Text(isIncome ? "Recebido" : "Pago")
                .foregroundStyle(.secondary)
        } else if daysUntilDue < 0 {
            Text("Atrasada há \(-daysUntilDue) dias")
                .foregroundStyle(.red)
        } else if daysUntilDue == 0 {
            Text("Vence hoje")
                .foregroundStyle(.orange)
        } else if daysUntilDue == 1 {
            Text("Vence amanhã")
                .foregroundStyle(.orange)
        } else {
            Text("Vence em \(daysUntilDue) dias")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        MonthlyEntryRowView(
            entry: MonthlyEntry(name: "Cartão Nubank", amount: 1234.56, referenceMonth: "26/06", dueDate: .now, type: .expense),
            onEdit: {},
            onTogglePaid: {}
        )
    }
}
