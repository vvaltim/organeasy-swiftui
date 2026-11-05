import SwiftData
import SwiftUI

struct StatementImportView: View {
    private enum Constants {
        static let visibleLimit = 50
    }

    let statement: Statement

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var existing: [MonthlyEntry]

    @State private var isInverted = false
    @State private var failedToSave = false

    private var plan: StatementImportPlan {
        StatementImportPlan(
            transactions: isInverted ? statement.transactions.map(\.inverted) : statement.transactions,
            existing: existing
        )
    }

    var body: some View {
        let plan = plan

        NavigationStack {
            List {
                Section {
                    LabeledContent("Formato", value: statement.format)
                    LabeledContent("Novos lançamentos", value: plan.newTransactions.count, format: .number)
                    if plan.duplicateCount > .zero {
                        LabeledContent("Já existentes", value: plan.duplicateCount, format: .number)
                    }
                    LabeledContent("Saídas", value: plan.expenseTotal.getLocalCurrency())
                    LabeledContent("Entradas", value: plan.incomeTotal.getLocalCurrency())
                }

                Section {
                    Toggle("Inverter entradas e saídas", isOn: $isInverted)
                } footer: {
                    Text("Use se os gastos aparecerem como entradas. Tudo entra como pago, na data do extrato.")
                }

                if !plan.newTransactions.isEmpty {
                    Section("Lançamentos") {
                        ForEach(Array(plan.newTransactions.prefix(Constants.visibleLimit).enumerated()), id: \.offset) { _, item in
                            row(item)
                        }

                        let hiddenCount = plan.newTransactions.count - Constants.visibleLimit
                        if hiddenCount > .zero {
                            Text("E mais \(hiddenCount)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Importar extrato")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Importar") {
                        save(plan)
                    }
                    .disabled(plan.newTransactions.isEmpty)
                    .accessibilityIdentifier("confirmImport")
                }
            }
            .alert("Não foi possível salvar os lançamentos.", isPresented: $failedToSave) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func row(_ item: StatementTransaction) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                Text(item.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(item.amount.getLocalCurrency())
                .foregroundStyle(item.type == .income ? .green : .primary)
        }
    }

    private func save(_ plan: StatementImportPlan) {
        do {
            try plan.apply(to: modelContext)
            dismiss()
        } catch {
            modelContext.rollback()
            failedToSave = true
        }
    }
}
