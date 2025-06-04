//
//  HomeView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    
    var body: some View {
        NavigationStack {
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
                            viewModel.detailItemTapped(transaction.dueDate.formatToMonthYear())
                        }
                    }
                }
            }
            .navigationTitle(Text("tab_home"))
            .toolbar {
                ToolbarItem {
                    Button(
                        action: {
                            viewModel.addButtonTapped()
                        }
                    ) {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(isPresented: $viewModel.goToTransactionView) {
                TransactionView(
                    viewModel: TransactionViewModel(
                        repository: viewModel.repository,
                        onClose: {
                            viewModel.goToTransactionView = false
                            
                            viewModel.fetchTransactions()
                        }
                    )
                )
            }
            .navigationDestination(isPresented: $viewModel.goToTransactionDetailView) {
                MonthTransactionDetailView(
                    viewModel: MonthTransactionDetailViewModel(
                        repository: viewModel.repository,
                        month: viewModel.selectedMonth
                    )
                )
            }
            .onAppear {
                viewModel.fetchTransactions()
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let repository = TransactionRepository(context: context)
    
    HomeView(
        viewModel: HomeViewModel(
            repository: repository
        )
    )
}
