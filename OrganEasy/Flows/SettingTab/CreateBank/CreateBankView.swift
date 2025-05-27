//
//  CreateBankView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//

import SwiftUI

struct CreateBankView: View {
    @StateObject var viewModel: CreateBankViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("Nome do Banco")
                ){
                    TextField(
                        "Nome",
                        text: $viewModel.name
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
    let repository: BankRepository = BankRepository(
        context: context
    )
    
    CreateBankView(
        viewModel: CreateBankViewModel(
            repository: repository,
            onClose: {}
        )
    )
}
