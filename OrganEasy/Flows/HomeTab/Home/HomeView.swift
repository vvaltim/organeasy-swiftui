//
//  HomeView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var provider: RepositoryProvider
    @StateObject var viewModel: HomeViewModel = HomeViewModel()
    @StateObject private var navManager = HomeNavigationManager()
    
    var body: some View {
        NavigationStack(path: $navManager.path) {
            Group {
                if viewModel.firstTransactionPerMonth.isEmpty {
                    EmptyStateView(
                        imageName: "tray",
                        title: "label_empty_data",
                        message: "",
                        actionTitle: nil,
                        action: { }
                    )
                } else {
                    List(viewModel.firstTransactionPerMonth, id: \.self) { transaction in
                        HStack {
                            Text(transaction.dueDate.formatToMonthYear())
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            navManager.path.append(HomeRouter.month(transaction.dueDate.formatToMonthYear()))
                        }
                    }
                }
            }
            .navigationTitle(Text("tab_home"))
            .toolbar {
                ToolbarItem {
                    Button(
                        action: {
                            navManager.path.append(HomeRouter.transaction(nil))
                        }
                    ) {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: HomeRouter.self) { router in
                switch router {
                case .month(let month):
                    MonthTransactionDetailView(
                        month: month
                    )
                case .transaction(let id):
                    TransactionView(
                        onClose: {
                            navManager.path.removeLast()
                            
                            viewModel.fetchTransactions()
                        },
                        transactionID: id
                    )
                }
            }
            .onAppear {
                viewModel.setupProvider(with: provider)
                
                viewModel.fetchTransactions()
                viewModel.requestNotificationPermission()
            }
        }
        .environmentObject(navManager)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let provider = RepositoryProvider(context: context)
    
    HomeView()
        .environmentObject(provider)
}
