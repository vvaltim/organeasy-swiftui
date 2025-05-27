//
//  SettingView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI

struct SettingView: View {
    let persistenceController = PersistenceController.shared
    
    @ObservedObject var viewModel: SettingViewModel
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Evolução")) {
                    Button {
                        viewModel.onTapBankList()
                    } label: {
                        Text("Gerenciar Bancos")
                    }
                }
                
                Section(header: Text("Appearance")) {
                    Toggle(isOn: $viewModel.isDarkMode) {
                        Text("Modo Escuro")
                    }
                }
                
            }
            .navigationTitle(Text("Ajustes"))
            .navigationDestination(
                isPresented: $viewModel.goToBankList
            ) {
                BankListView(
                    viewModel: BankListViewModel(
                        repository: BankRepository(
                            context: persistenceController.container.viewContext
                        )
                    )
                )
            }
        }
    }
}

#Preview {
    let mock = SettingViewModel()
    
    SettingView(viewModel: mock)
}
