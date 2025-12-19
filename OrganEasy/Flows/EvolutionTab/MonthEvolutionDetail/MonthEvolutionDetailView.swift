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
            Section(header: headerView) {
                ForEach(viewModel.evolutions, id: \.objectID) { evolution in
                    EvolutionRow(evolution: evolution)
                        .contentShape(Rectangle())
                        .listRowBackground(rowBackground(for: evolution))
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
        }
        .navigationTitle(titleText)
        .onAppear {
            viewModel.setupProvider(with: provider)
            viewModel.month = month
            viewModel.getEvolutionsPerMonth()
        }
    }
    
    private var headerView: some View {
        MonthEvolutionHeaderView(
            label: "header_evolution_sum",
            value: viewModel.total
        )
        .listRowInsets(EdgeInsets())
        .background(Color.clear)
    }

    private var titleText: String {
        viewModel.evolutions.first?.date?.formatTo() ?? ""
    }

    private func rowBackground(for evolution: Evolution) -> some View {
        if evolution.addWithIA {
            return AnyView(
                AppleIntelligenceGradientBackground()
            )
        } else {
            return AnyView(Color(UIColor.secondarySystemGroupedBackground))
        }
    }
    
    private struct EvolutionRow: View {
        let evolution: Evolution

        var body: some View {
            HStack {
                Text(evolution.bank?.name ?? "")
                Spacer()
                Text(evolution.value.toBRL())
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
