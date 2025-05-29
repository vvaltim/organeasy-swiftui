//
//  CreateEvolutionView.swift
//  OrganEasy
//
//  Created by Walter Vanio dos Reis Junior on 29/05/25.
//

import SwiftUI

struct CreateEvolutionView: View {
    @StateObject var viewModel: CreateEvolutionViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("Detalhes")
                ){
                    Picker(
                        "Banco",
                        selection: $viewModel.selectedBank) {
                            ForEach(0..<viewModel.bankList.count, id: \.self) { index in
                                Text(viewModel.bankList[index].name ?? "Desconhecido")
                            }
                        }
                    
                    CurrencyTextField(
                        value: $viewModel.value
                    )
                    
                }
                Section {
                    Button("Salvar") {
//                        viewModel.saveAction()
                    }
                    //.disabled(viewModel.isDissabledSaveButton)
                }
                
                .navigationBarTitle("Lançamento", displayMode: .inline)
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let bankRepository: BankRepository = BankRepository(
        context: context
    )
    let evolutionRepository: EvolutionRepository = EvolutionRepository(
        context: context
    )
    
    CreateEvolutionView(
        viewModel: CreateEvolutionViewModel(
            bankRepository: bankRepository,
            evolutionRepository: evolutionRepository
        )
    )
}
