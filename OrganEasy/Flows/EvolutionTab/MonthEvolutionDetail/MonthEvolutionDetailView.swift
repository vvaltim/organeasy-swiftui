//
//  MonthEvolutionDetailView.swift
//  OrganEasy
//
//  Created by Walter Vanio dos Reis Junior on 29/05/25.
//

import SwiftUI

struct MonthEvolutionDetailView: View {
    
    @StateObject var viewModel: MonthEvolutionDetailViewModel
    
    var body: some View {
        List {
            Section(
                header: MonthEvolutionHeaderView(
                    label: "Total",
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
                }
            }
        }
    }
}

#Preview {
    let container = PersistenceController.preview.container
    
    MonthEvolutionDetailView(
        viewModel: MonthEvolutionDetailViewModel(
            repository: EvolutionRepository(
                context: container.viewContext
            ),
            month: "Maio de 2025"
        )
    )
}
