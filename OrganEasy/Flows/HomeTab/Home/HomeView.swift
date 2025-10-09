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
                    VStack {
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        
                        List {
                            Section(
                                header: FinanceSummaryCard(
                                    input: viewModel.input,
                                    output: viewModel.output
                                )
                                .padding(.vertical, 20)
                                .listRowInsets(EdgeInsets())
                            ) {
                                ForEach(viewModel.transactions, id: \.objectID) { transaction in
                                    MonthTransactionDetailItemView(
                                        descriptionText: transaction.descriptionText,
                                        dueDate: transaction.dueDate.formatTo(dateFormat: "dd/MM"),
                                        paymentDate: transaction.paymentDate?.formatTo(dateFormat: "dd/MM"),
                                        ammount: transaction.amount.toBRL(),
                                        isIncome: transaction.isIncome,
                                        isSlash: transaction.isSlash,
                                        canPay: transaction.canPay(),
                                        canSlash: transaction.canSlash()
                                    ) { type in
                                        switch type {
                                        case .tap:
                                            navManager.path.append(HomeRouter.transaction(transaction.id))
                                        case .paid:
                                            viewModel.markToPaid(transaction: transaction)
                                        case .slash:
                                            viewModel.changeSlash(transaction: transaction)
                                        case .delete:
                                            viewModel.delete(transaction: transaction)
                                        }
                                    }
                                    .listRowBackground(rowBackground(for: transaction))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text("tab_home"))
            .navigationBarTitleDisplayMode(.inline)
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
    
    private func rowBackground(for transaction: Transaction) -> some View {
        if transaction.addWithIA {
            return AnyView(
                AppleIntelligenceGradientBackground()
            )
        } else {
            return AnyView(Color(UIColor.secondarySystemGroupedBackground))
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let provider = RepositoryProvider(context: context)
    
    HomeView()
        .environmentObject(provider)
}
