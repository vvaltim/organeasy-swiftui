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
    
    @Generable
    struct Arguments { }
    
    func call(arguments: Arguments) async throws -> String {
        let nextTransactions = transactions.filter { $0.paymentDate == nil && $0.isIncome == false }
        
        
        if nextTransactions.isEmpty {
            return "Não há transações há vencer no momento."
        } else {
            return nextTransactions.map { transaction in
                return " \(transaction.descriptionText) no valor de \(transaction.amount.toBRL()) com vencimento em \(transaction.dueDate.formatTo())"
            }.joined(separator: ", ")
        }
    }
}
