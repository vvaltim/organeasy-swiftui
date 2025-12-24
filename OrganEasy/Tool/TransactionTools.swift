//
//  TransactionTool.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 17/12/25.
//

import Foundation
import FoundationModels

struct TransactionTool: Tool {
    let name: String = "transactionTool"
    let description: String = "Encontrar informações sobre suas transações a vencer."
    let transactions: [TransactionDTO]
    
    func call() async throws -> String {
        let nextTransactions = transactions.filter { $0.paymentDate != nil }
        
        
        if nextTransactions.isEmpty {
            return "Não há transações há vencer no momento."
        } else {
            return transactions.map { transaction in
                let dueDateString = transaction.dueDate.formatTo()
                let paymentString = transaction.paymentDate != nil ? "pago no dia \(transaction.paymentDate?.formatTo() ?? "")" : "em aberto"
                return "\(transaction.descriptionText) no valor de \(transaction.amount) com vencimento no dia \(dueDateString) \(paymentString)"
            }.joined(separator: ", ")
        }
    }
}
