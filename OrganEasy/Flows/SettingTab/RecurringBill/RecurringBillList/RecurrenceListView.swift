//
//  RecurrenceListView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 17/06/25.
//

import SwiftUI

struct RecurrenceListView: View {
    
    @EnvironmentObject var provider: RepositoryProvider
    @EnvironmentObject var navManager: SettingNavigationManager
    
    @StateObject var viewModel: RecurrenceListViewModel = RecurrenceListViewModel()
    
    var body: some View {
        Group {
            if viewModel.recurrenceList.isEmpty {
                EmptyStateView(
                    imageName: "tray",
                    title: "label_empty_data",
                    message: "",
                    actionTitle: nil,
                    action: { }
                )
            } else {
                List(viewModel.recurrenceList, id: \.self) { recurrence in
                    Text(recurrence)
                }
            }
        }
        .navigationTitle(Text("navigation_recurring_bill_title"))
        .toolbar {
            ToolbarItem {
                Button(
                    action: {
                        navManager.path.append(SettingRouter.recurringBillForm(nil))
                    }
                ) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            viewModel.setup(with: provider.recurringBillRepository)
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let provider = RepositoryProvider(context: context)
    let navController = SettingNavigationManager()
    
    RecurrenceListView()
        .environmentObject(provider)
        .environmentObject(navController)
}
