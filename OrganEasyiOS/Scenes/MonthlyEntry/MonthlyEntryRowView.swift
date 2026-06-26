import SwiftUI

struct MonthlyEntryRowView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: MonthlyEntry
    let onEdit: () -> Void
    let onTogglePaid: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack {
                ZStack {
                    Text(entry.dueDate, format: Date.FormatStyle().day())
                        .font(.title3)
                        .monospacedDigit()
                        .frame(width: Size.x36.rawValue, alignment: .leading)
                }

                Text(entry.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Text((entry.type == .expense ? -1 : 1) * (entry.amount), format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(entry.paymentDate == nil ? "Mark Paid" : "Unmark") {
                onTogglePaid()
            }.tint(.blue)
        }
    }
}

// MARK: - Preview

#Preview {
    MonthlyEntryRowView(
        entry: MonthlyEntry(
            name: "Nubank",
            amount: 12344.56,
            referenceMonth: "26/06",
            dueDate: Date.now,
            type: .expense
        ),
        onEdit: {
            
        },
        onTogglePaid: {
            
        }
    )
}
