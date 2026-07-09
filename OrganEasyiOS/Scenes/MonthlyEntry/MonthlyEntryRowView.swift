import SwiftUI

struct MonthlyEntryRowView: View {
    let entry: MonthlyEntry
    let onEdit: () -> Void
    let onTogglePaid: () -> Void
    
    private var isStrike: Bool {
        entry.paymentDate != nil
    }

    var body: some View {
        Button(action: onEdit) {
            HStack {
                ZStack {
                    Text(entry.dueDate, format: Date.FormatStyle().day())
                        .font(.title3)
                        .monospacedDigit()
                        .frame(width: Size.x36.rawValue, alignment: .leading)
                        .strikethrough(isStrike)
                }

                Text(entry.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .strikethrough(isStrike)

                Spacer()

                Text((entry.type == .expense ? -1 : 1) * (entry.amount), format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .strikethrough(isStrike)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(entry.paymentDate == nil ? OrganEasyStrings.Row.markPaid : OrganEasyStrings.Row.unmark) {
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
