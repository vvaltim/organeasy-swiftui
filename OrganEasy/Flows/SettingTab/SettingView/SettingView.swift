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
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("tab_evolution")) {
                    Button {
                        viewModel.onTapBankList()
                    } label: {
                        Text("button_bank_management")
                    }
                }
                
                Section(header: Text("section_appearance")) {
                    Toggle(isOn: $viewModel.isDarkMode) {
                        Text("toggle_dark_mode")
                    }
                }
                
                Section(header: Text("section_icloud_sync")) {
                    HStack {
                        Text("label_icloud")
                        Spacer()
                        Text(viewModel.iCloudStatus)
                    }
                }
                
                Section(header: Text("section_about")) {
                    HStack {
                        Text("label_version")
                        Spacer()
                        Text(viewModel.version)
                    }
                }
                
                Section(header: Text("section_data")) {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Text("button_clear_data")
                    }
                }
                .alert("Tem certeza?", isPresented: $showDeleteAlert) {
                    Button("Apagar", role: .destructive) {
                        viewModel.clearAllData()
                    }
                    Button("Cancelar", role: .cancel) { }
                } message: {
                    Text("Esta ação irá apagar todos os dados do app. Deseja continuar?")
                }
            }
            .navigationTitle(Text("tab_settings"))
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
