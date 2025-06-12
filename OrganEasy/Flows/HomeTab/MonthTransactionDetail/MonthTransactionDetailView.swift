//
//  MonthTransactionDetailView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 22/05/25.
//

import SwiftUI

struct MonthTransactionDetailView: View {
    
    @EnvironmentObject var provider: RepositoryProvider
    @StateObject var viewModel: MonthTransactionDetailViewModel = MonthTransactionDetailViewModel()
    let month: String
    
    var body: some View {
        List {
            Section(
                header: FinanceSummaryCard(
                    input: viewModel.input,
                    output: viewModel.output
                )
                .listRowInsets(EdgeInsets())
            ) {
                transactionList
            }
        }
        .animation(.default, value: viewModel.transactions)
        .navigationTitle(viewModel.month)
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
    let repository = TransactionRepository(context: context)
    let month = Date().addingTimeInterval(Double(1) * 86400)
    
    MonthTransactionDetailView(
        month: month.formatToMonthYear()
    )
}
