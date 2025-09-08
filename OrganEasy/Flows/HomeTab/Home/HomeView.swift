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
    @State private var selectedMonth: Date? = Date()
    
    var body: some View {
        NavigationStack(path: $navManager.path) {
            Group {
                if viewModel.transactions.isEmpty {
                    EmptyStateView(
                        imageName: "tray",
                        title: "label_empty_data",
                        message: "",
                        actionTitle: nil,
                        action: { }
                    )
                } else {
                    List {
                        Section(
                            header:
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.months, id: \.self) { month in
                                            FilterChipView(
                                                label: month.formatToMonthYear(),
                                                isSelected: selectedMonth == month,
                                                action: {
                                                    selectedMonth = month
                                                    viewModel.filterPerMonth(with: month)
                                                }
                                            )
                                        }
                                    }
                                    .padding(.vertical, 16)
                                }
                                .padding(.horizontal, -20)
                        ) {
                            ForEach(viewModel.transactions, id: \.self) { transaction in
                                HStack {
                                    Text(transaction.descriptionText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    navManager.path.append(HomeRouter.month(transaction.dueDate.formatToMonthYear()))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text("tab_home"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
                
                selectedMonth = viewModel.months.first
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
