//
//  MonthTransactionDetailViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 22/05/25.
//

import SwiftUI

class MonthTransactionDetailViewModel: ObservableObject {
    
    private var repository: TransactionRepositoryProtocol
    
    @Published var transactions: [Transaction] = []
    @Published var month: String = ""
    
    var input: Double {
        var sum: Double = 0
        for item in transactions {
            if item.isIncome {
                sum += item.amount
            }
        }
        return sum
    }
    
    var output: Double {
        var sum: Double = 0
        for item in transactions {
            if !item.isIncome {
                sum += item.amount
            }
        }
        return sum
    }
    
    init(repository: TransactionRepositoryProtocol, month: String) {
        self.repository = repository
        self.month = month
    }
    
    // MARK: - Public Methods
    
    func getTransactionsPerMonth() {
        let allTransactions = repository.fetchAll()
        
        transactions = allTransactions.filter {
            $0.dueDate.formatToMonthYear() == month
        }
    }
    
    func markToPaid(transaction: Transaction) {
        repository.markToPaid(with: transaction)
        
        getTransactionsPerMonth()
    }
    
    func delete(transaction: Transaction) {
        repository.remove(with: transaction)
        
        getTransactionsPerMonth()
    }
    
    func changeSlash(transaction: Transaction) {
        repository.changeSlash(with: transaction)
        
        getTransactionsPerMonth()
    }
    
}
