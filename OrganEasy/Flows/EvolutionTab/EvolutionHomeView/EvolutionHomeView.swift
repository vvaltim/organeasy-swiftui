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
                    header: HeaderChartView()
                ) {
                    HStack {
                        Text(Date().formatToMonthYear())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                                                
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
                        )
                    )
                )
            }
        }
    }
}

#Preview {
    EvolutionHomeView(viewModel: EvolutionHomeViewModel())
}
