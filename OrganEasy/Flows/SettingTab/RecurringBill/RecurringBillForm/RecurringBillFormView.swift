//
//  RecurringBillForm.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 23/06/25.
//

import SwiftUI

struct RecurringBillFormView: View {
    
    @EnvironmentObject var provider: RepositoryProvider
    @StateObject var viewModel: RecurringBillFormViewModel = RecurringBillFormViewModel()
    
    let onClose: () -> Void
    var recurringBillID: UUID? = nil
    
    var body: some View {
        Form {
            Section(
                header: Text("section_details")
            ) {
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
            
            viewModel.setupRecurringBill(with: recurringBillID)
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let provider = RepositoryProvider(context: context)
    let navController = SettingNavigationManager()
    
    RecurringBillFormView(onClose: { })
        .environmentObject(provider)
        .environmentObject(navController)
}
