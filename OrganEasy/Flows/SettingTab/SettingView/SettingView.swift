//
//  SettingView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI

struct SettingView: View {
    
    let persistenceController = PersistenceController.shared
    
    @ObservedObject var viewModel: SettingViewModel = SettingViewModel()
    
    @StateObject private var navManager = SettingNavigationManager()
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationStack(path: $navManager.path) {
            List {
                Section(header: Text("Gerenciar")) {
                    Button {
                        navManager.path.append(SettingRouter.bank)
                    } label: {
                        Text("button_bank_management")
                    }
                    
                    Button {
                        navManager.path.append(SettingRouter.recurringBillList)
                    } label: {
                        Text("button_recurring_bill")
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
                .alert("alert_sure", isPresented: $showDeleteAlert) {
                    Button("button_delete", role: .destructive) {
                        viewModel.clearAllData()
                    }
                    Button("button_cancel", role: .cancel) { }
                } message: {
                    Text("action_delete_all_data")
                }
            }
            .navigationTitle(Text("tab_settings"))
            .navigationDestination(for: SettingRouter.self) { router in
                switch router {
                case .bank:
                    BankListView()
                case .recurringBillList:
                    RecurrenceListView()
                case .recurringBillForm(let id):
                    RecurringBillForm()
                }
            }
        }
        .environmentObject(navManager)
    }
}

#Preview {
    let mock = SettingViewModel()
    
    let context = PersistenceController.preview.container.viewContext
    let provider = RepositoryProvider(context: context)
    
    SettingView(viewModel: mock)
        .environmentObject(provider)
}
