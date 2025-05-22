//
//  HomeView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    let persistenceController = PersistenceController.shared
    
    var body: some View {
        NavigationStack {
            List(viewModel.firstTransactionPerMonth, id: \.self) { transaction in
                HStack {
                    Text(transaction.getMonthTitle())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.detailItemTapped(transaction.getMonthTitle())
                }
            }
            .navigationTitle(Text("Início"))
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
                        context: persistenceController.container.viewContext,
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
                        transactions: viewModel.detailItems
                    )
                )
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    HomeView(
        viewModel: HomeViewModel(
            context: context
        )
    )
}
