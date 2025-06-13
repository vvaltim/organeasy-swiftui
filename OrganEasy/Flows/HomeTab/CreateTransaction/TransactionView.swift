//
//  TransactionView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI

struct TransactionView: View {
    
    @EnvironmentObject var provider: RepositoryProvider
    @StateObject var viewModel: TransactionViewModel = TransactionViewModel()
    
    let onClose: () -> Void
    var transactionID: UUID? = nil
    
    var body: some View {
        Form {
            Section(
                header: Text("section_details")
            ) {
                Picker(
                    "label_transaction_type",
                    selection: $viewModel.isIncome) {
                        Text("picker_input").tag(true)
                        Text("picker_output").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                
                TextField(
                    "textfield_description",
                    text: $viewModel.description
                )
                
                CurrencyTextField(
                    value: $viewModel.amount
                )
                
                DatePicker(
                    "date_picker_due_date",
                    selection: $viewModel.dueDate, displayedComponents: .date
                )
            }
        }
        
        .navigationTitle(Text("navigation_transaction_title"))
        .toolbar {
            ToolbarItem {
                Button(
                    action: {
                        viewModel.saveAction()
                        
                        onClose()
                    }
                ) {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isDissabledSaveButton)
            }
        }
        .onAppear {
            viewModel.setupProvider(with: provider)
            
            viewModel.setupTransaction(with: transactionID)
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    TransactionView(onClose: { })
}
