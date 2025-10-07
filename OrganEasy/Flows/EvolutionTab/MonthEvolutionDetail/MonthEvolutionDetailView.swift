//
//  MonthEvolutionDetailView.swift
//  OrganEasy
//
//  Created by Walter Vanio dos Reis Junior on 29/05/25.
//

import SwiftUI

struct MonthEvolutionDetailView: View {
    
    @EnvironmentObject var provider: RepositoryProvider
    @EnvironmentObject var navManager: EvolutionNavigationManager
    @StateObject var viewModel: MonthEvolutionDetailViewModel = MonthEvolutionDetailViewModel()
    
    let month: String
    
    var body: some View {
        List {
            Section(
                header: MonthEvolutionHeaderView(
                    label: "header_evolution_sum",
                    value: viewModel.total
                )
                .listRowInsets(EdgeInsets())
                .background(Color.clear)
            ) {
                ForEach(viewModel.evolutions, id: \.objectID) { evolution in
                    HStack {
                        Text(evolution.bank?.name ?? "")
                        Spacer()
                        Text(evolution.value.toBRL())
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        navManager.path.append(EvolutionRouter.evolution(evolution.id))
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.delete(with: evolution)
                        } label: {
                            Label(
                                "button_delete",
                                systemImage: "trash.fill"
                            )
                        }
                    }
                }
            }
            .navigationTitle(Text(viewModel.evolutions.first?.date?.formatTo() ?? ""))
            .onAppear {
                viewModel.setupProvider(with: provider)
                viewModel.month = month
                viewModel.getEvolutionsPerMonth()
            }
        }
    }
}

#Preview {
    let container = PersistenceController.preview.container
    
    MonthEvolutionDetailView(
        month: "Maio de 2025"
    )
}
