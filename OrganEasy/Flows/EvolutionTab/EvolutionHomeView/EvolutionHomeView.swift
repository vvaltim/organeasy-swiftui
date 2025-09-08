//
//  EvolutionHomeView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//

import SwiftUI

struct EvolutionHomeView: View {
    
    @EnvironmentObject var provider: RepositoryProvider
    @StateObject private var navManager = EvolutionNavigationManager()
    @StateObject var viewModel: EvolutionHomeViewModel = EvolutionHomeViewModel()
    
    var body: some View {
        NavigationStack(path: $navManager.path) {
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
                            .padding(.bottom, 24)
                        ) {
                            let months = Array(viewModel.groupedByMonth.keys.sorted())
                            
                            ForEach(months, id: \.self) { month in
                                let evolutions = viewModel.groupedByMonth[month] ?? []
                                
                                MonthEvolutionRow(
                                    month: month,
                                    evolutions: evolutions,
                                    total: viewModel.getTotalByMonth(month: month)
                                ) {
                                    if let first = evolutions.first, let dateFormatted = first.date?.formatToMonthYear() {
                                        navManager.path.append(EvolutionRouter.month(dateFormatted))
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
                        navManager.path.append(EvolutionRouter.evolution(nil))
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: EvolutionRouter.self) { router in
                switch router {
                case .evolution(let uuid):
                    CreateEvolutionView(
                        uuid: uuid
                    )
                case .month(let month):
                    MonthEvolutionDetailView(
                        month: month
                    )
                }
            }
            .onAppear {
                viewModel.setupProvider(with: provider)
                viewModel.fetchAll()
            }
        }
        .environmentObject(navManager)
    }
}

#Preview {
    let container = PersistenceController.preview.container
    
    EvolutionHomeView()
}
