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
        NavigationStack {
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
                        }
                    ) {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isDissabledSaveButton)
                }
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let repository = TransactionRepository(context: context)
    TransactionView(
        viewModel: TransactionViewModel(
            repository: repository,
            onClose: { }
        )
    )
}
