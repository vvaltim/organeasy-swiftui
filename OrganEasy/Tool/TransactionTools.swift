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
    let description: String = "Encontrar informaçãoes sobre suas transações."
    let transactions: [TransactionDTO]
    
    @Generable
    struct Arguments {
        @Guide(description: "A data de vencimento a ser pesquisada.")
        let date: String
    }
    
    func call(arguments: Arguments) async throws -> String {
//        let calendar = Calendar.current
//        let targetMonth = calendar.component(.month, from: arguments.date)
//        let targetYear = calendar.component(.year, from: arguments.date)
        
        return transactions
//            .filter { transaction in
//                let month = calendar.component(.month, from: transaction.dueDate)
//                let year = calendar.component(.year, from: transaction.dueDate)
//                return month == targetMonth && year == targetYear
//            }
            .map { transaction in
                let dueDateString = transaction.dueDate.formatTo()
                let paymentString = transaction.paymentDate != nil ? "pago no dia \(transaction.paymentDate?.formatTo() ?? "")" : "em aberto"
                return "\(transaction.descriptionText) no valor de \(transaction.amount) com vencimento no dia \(dueDateString) \(paymentString)"
            }.joined(separator: ", ")
    }
}
