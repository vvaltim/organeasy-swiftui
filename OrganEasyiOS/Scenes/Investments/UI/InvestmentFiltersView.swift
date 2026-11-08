import SwiftUI

struct InvestmentFiltersView: View {
    @Binding var filters: InvestmentFilters

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Ordenar por") {
                    Picker("Ordenar por", selection: $filters.sort) {
                        ForEach(InvestmentFilters.Sort.allCases) { sort in
                            Text(sort.title).tag(sort)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Filtrar") {
                    Toggle("Só empresas com lucro", isOn: $filters.onlyProfitable)
                    Toggle("Só ativos em alta hoje", isOn: $filters.onlyRising)
                    VStack(alignment: .leading) {
                        Text("ROE mínimo: \(Int(filters.minimumROE))%")
                        Slider(value: $filters.minimumROE, in: 0...40, step: 5)
                    }
                }

                if filters.isActive {
                    Button("Limpar filtros", role: .destructive) {
                        filters = InvestmentFilters()
                    }
                }
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aplicar") { dismiss() }
                }
            }
            .onChange(of: filters) { _, value in
                InvestmentEvent.filterChanged(value.sort.rawValue).log()
            }
        }
    }
}
