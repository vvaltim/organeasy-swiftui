//
//  MonthTransactionDetailView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 22/05/25.
//

import SwiftUI

struct MonthTransactionDetailView: View {
    
    @StateObject var viewModel: MonthTransactionDetailViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.transactions, id: \.id) { transaction in
                MonthTransactionDetailItemView(transaction: transaction)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        if transaction.paymentDate == nil && !transaction.isIncome {
                            Button {
                                viewModel
                            } label: {
                                Label(
                                    "Pagar",
                                    systemImage: "checkmark.circle"
                                )
                            }
                            .tint(.green)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            viewModel
                        } label: {
                            Label(
                                "Excluir",
                                systemImage: "trash.circle"
                            )
                        }
                        .tint(.red)
                    }
            }
        }
        .navigationTitle(viewModel.month)
    }
}

#Preview {
    var context = PersistenceController.preview.container.viewContext
    
    let transaction = Transaction(context: context)
    transaction.id = UUID()
    transaction.descriptionText = "Teste"
    transaction.dueDate = Date()
    transaction.amount = 100
    transaction.isIncome = false
    
    let viewModel = MonthTransactionDetailViewModel(
        transactions: [
            transaction,
            transaction
        ]
    )

    return MonthTransactionDetailView(
        viewModel: viewModel
    )
}
