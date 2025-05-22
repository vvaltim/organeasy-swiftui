//
//  TransactionView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI

struct TransactionView: View {
    @StateObject var viewModel: TransactionViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transação")){
                    Picker(
                        "Tipo de movimentação",
                        selection: $viewModel.isIncome) {
                            Text("Entrada").tag(true)
                            Text("Saída").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    
                    TextField(
                        "Descrição",
                        text: $viewModel.description
                    )
                    
                    CurrencyTextField(
                        value: $viewModel.amount
                    )
                    
                    DatePicker(
                        "Data de Vencimento",
                        selection: $viewModel.dueDate, displayedComponents: .date
                    )
                    
                    
                }
                Section {
                    Button("Salvar") {
                        viewModel.saveAction()
                    }
                    .disabled(viewModel.isDissabledSaveButton)
                }
                
                .navigationBarTitle("Lançamento", displayMode: .inline)
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    TransactionView(
        viewModel: TransactionViewModel(
            context: context
        )
    )
}
