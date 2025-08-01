//
//  EvolutionHomeView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//

import SwiftUI

struct EvolutionHomeView: View {
    
    @EnvironmentObject var provider: RepositoryProvider
    @StateObject var viewModel: EvolutionHomeViewModel = EvolutionHomeViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.groupedByMonth.isEmpty {
                    EmptyStateView(
                        imageName: "tray",
                        title: "label_empty_data",
                        message: "",
                        actionTitle: nil,
                        action: { }
                    )
                } else {
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
                }
            }
            .navigationTitle(Text("tab_evolution"))
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
                    onClose: {
                        viewModel.closeCreateEvolution()
                    }
                )
            }
            .navigationDestination(isPresented: $viewModel.goToDetailEvolution) {
                MonthEvolutionDetailView(
                    month: viewModel.selectedMonth
                )
            }
            .onAppear {
                viewModel.setupProvider(with: provider)
                viewModel.fetchAll()
            }
        }
    }
}

#Preview {
    let container = PersistenceController.preview.container
    
    EvolutionHomeView()
}
