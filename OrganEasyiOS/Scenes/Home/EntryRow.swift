//
//  EntryRow.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 19/06/26.
//

import SwiftUI

struct EntryRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: MonthlyEntry
    let onEdit: () -> Void
    let onTogglePaid: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack {
                ZStack {
                    Image(systemName: entry.type == .income ? "arrow.down.circle" : "arrow.up.circle")
                        .foregroundStyle(entry.type == .income ? .green : .red)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(entry.dueDate, format: Date.FormatStyle().day().month(.wide))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(entry.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.subheadline)
                        .monospacedDigit()
                    HStack(spacing: 6) {
                        Text(entry.paymentDate == nil ? "Aberto" : "Pago")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
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

#Preview {
    EntryRow(
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
