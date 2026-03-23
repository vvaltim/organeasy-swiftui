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
                if viewModel.monthsWithTotal.isEmpty {
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
                            ForEach(viewModel.monthsWithTotal.reversed(), id: \.0) { month in
                                let monthString = month.0.formatToMonthYear()
                                MonthEvolutionRow(
                                    month: monthString,
                                    total: month.1
                                ) {
                                    navManager.path.append(EvolutionRouter.month(monthString))
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
