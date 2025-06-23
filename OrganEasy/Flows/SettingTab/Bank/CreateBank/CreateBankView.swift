//
//  CreateBankView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//

import SwiftUI

struct CreateBankView: View {
    
    @EnvironmentObject var provider: RepositoryProvider
    @StateObject var viewModel: CreateBankViewModel = CreateBankViewModel()
    
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("section_bank_name")
                ){
                    TextField(
                        "textfield_name",
                        text: $viewModel.name
                    )
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
            }
        }
        .onAppear {
            viewModel.setup(with: provider)
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let provider = RepositoryProvider(context: context)
    
    CreateBankView(onClose: {})
        .environmentObject(provider)
}
