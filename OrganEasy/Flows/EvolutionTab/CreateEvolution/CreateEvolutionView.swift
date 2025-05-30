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
                    header: Text("section_details")
                ){
                    Picker(
                        "textfield_name",
                        selection: $viewModel.selectedBank) {
                            ForEach(0..<viewModel.bankList.count, id: \.self) { index in
                                Text(viewModel.bankList[index].name ?? "Desconhecido")
                            }
                        }
                    
                    DatePicker(
                        "date_picker_date",
                        selection: $viewModel.date, displayedComponents: .date
                    )
                    
                    CurrencyTextField(
                        value: $viewModel.amount
                    )
                    
                }
                Section {
                    Button("button_save") {
                        viewModel.saveEvolution()
                    }
                }
                
                .navigationBarTitle("navigation_transaction_title", displayMode: .inline)
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
            evolutionRepository: evolutionRepository,
            onClose: {
                
            }
        )
    )
}
