//
//  EvolutionHomeView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//

import SwiftUI

struct EvolutionHomeView: View {
    let persistenceController = PersistenceController.shared
    
    @StateObject var viewModel: EvolutionHomeViewModel
    
    var body: some View {
        NavigationStack {
            List {
                Section(
                    header: HeaderChartView(
                        chartData: viewModel.chartData
                    )
                    .listRowInsets(EdgeInsets())
                    .background(Color.clear)
                ) {
                    ForEach(Array(viewModel.groupedByMonth.keys.sorted()), id: \.self) { month in
                        let evolutions = viewModel.groupedByMonth[month] ?? []
                        HStack {
                            Text(month)
                            Spacer()
                            Text(viewModel.getTotalByMonth(month: month).toBRL())
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let first = evolutions.first {
                                viewModel.openDetailsEvolution(first)
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text("Evolução"))
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        viewModel.openCreateEvolution()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(isPresented: $viewModel.goToCreateEvolution) {
                CreateEvolutionView(
                    viewModel: CreateEvolutionViewModel(
                        bankRepository: BankRepository(
                            context: persistenceController.container.viewContext
                        ),
                        evolutionRepository: EvolutionRepository(
                            context: persistenceController.container.viewContext
                        ),
                        onClose: {
                            viewModel.closeCreateEvolution()
                        }
                    )
                )
            }
            .navigationDestination(isPresented: $viewModel.goToDetailEvolution) {
                MonthEvolutionDetailView(
                    viewModel: MonthEvolutionDetailViewModel(
                        repository: EvolutionRepository(
                            context: persistenceController.container.viewContext
                        ),
                        month: viewModel.selectedMonth
                    )
                )
            }
        }
    }
}

#Preview {
    let container = PersistenceController.preview.container
    
    EvolutionHomeView(
        viewModel: EvolutionHomeViewModel(
            repository: EvolutionRepository(
                context: container.viewContext
            )
        )
    )
}
