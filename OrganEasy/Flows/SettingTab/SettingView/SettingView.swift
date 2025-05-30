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
