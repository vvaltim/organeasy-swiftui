//
//  MonthTransactionDetailView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 22/05/25.
//

import SwiftUI

struct MonthTransactionDetailView: View {
    
    @EnvironmentObject var provider: RepositoryProvider
    @EnvironmentObject var navManager: HomeNavigationManager
    @StateObject var viewModel: MonthTransactionDetailViewModel = MonthTransactionDetailViewModel()
    @State private var showAlertDuplicate = false
    let month: String
    
    var body: some View {
        List {
            Section(
                header: FinanceSummaryCard(
                    input: viewModel.input,
                    output: viewModel.output
                )
                .padding(.bottom, 24)
                .listRowInsets(EdgeInsets())
            ) {
                transactionList
            }
        }
        .animation(.default, value: viewModel.transactions)
        .navigationTitle(viewModel.month)
        .toolbar {
            if viewModel.showDuplicateButton {
                ToolbarItem {
                    Button(
                        action: {
                            showAlertDuplicate = true
                        }
                    ) {
                        Image(systemName: "doc.on.doc")
                    }
                }
            }
        }
        .alert("Deseja mesmo duplicar os itens do mês selecionado, e inserir no mês atual?", isPresented: $showAlertDuplicate) {
            Button("button_yes", role: .destructive) {
                viewModel.duplicateMonth()
            }
            Button("button_no", role: .cancel) {
                showAlertDuplicate = false
            }
        }
        .onAppear {
            viewModel.setupProvider(with: provider)
            viewModel.month = month
            viewModel.getTransactionsPerMonth()
        }
    }
    
    @ViewBuilder
    var transactionList: some View {
        ForEach(viewModel.transactions, id: \.objectID) { transaction in
            MonthTransactionDetailItemView(
                descriptionText: transaction.descriptionText,
                dueDate: transaction.dueDate.formatTo(dateFormat: "dd/MM"),
                paymentDate: transaction.paymentDate?.formatTo(dateFormat: "dd/MM"),
                ammount: transaction.amount.toBRL(),
                isIncome: transaction.isIncome,
                isSlash: transaction.isSlash
            )
            .onTapGesture {
                navManager.path.append(HomeRouter.transaction(transaction.id))
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                if transaction.canPay() {
                    Button {
                        viewModel.markToPaid(transaction: transaction)
                    } label: {
                        Label(
                            "button_pay",
                            systemImage: "checkmark.circle"
                        )
                    }
                    .tint(.green)
                }
                
                if transaction.canSlash() {
                    Button {
                        viewModel.changeSlash(
                            transaction: transaction
                        )
                    } label: {
                        Label(
                            transaction.isSlash ? "button_strikethrough_off" : "button_strikethrough_on" ,
                            systemImage: transaction.isSlash ? "pencil" : "pencil.slash"
                        )
                    }
                    .tint(.gray)
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    viewModel.delete(transaction: transaction)
                } label: {
                    Label(
                        "button_delete",
                        systemImage: "trash.fill"
                    )
                }
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let repository = RepositoryProvider(context: context)
    let navManager = HomeNavigationManager()
    let month = Date().addingTimeInterval(Double(1) * 86400)
    
    MonthTransactionDetailView(
        month: month.formatToMonthYear()
    )
    .environmentObject(repository)
    .environmentObject(navManager)
}
