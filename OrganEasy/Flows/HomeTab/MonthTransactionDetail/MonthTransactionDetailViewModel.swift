//
//  MonthTransactionDetailViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 22/05/25.
//

import SwiftUI

class MonthTransactionDetailViewModel: ObservableObject {
    
    private var repository: TransactionRepositoryProtocol?
    
    @Published var transactions: [Transaction] = []
    @Published var month: String = ""
    
    // MARK: - Navigation
    
    @Published var goToEditView = false
    var selectedTransaction: Transaction?
    
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
    
    // MARK: - Public Methods
    
    func setupProvider(with provider: RepositoryProvider) {
        repository = provider.transactionRepository
    }
    
    func getTransactionsPerMonth() {
        let allTransactions = repository?.fetchAll() ?? []
        
        transactions = allTransactions.filter {
            $0.dueDate.formatToMonthYear() == month
        }
    }
    
    func markToPaid(transaction: Transaction) {
        repository?.markToPaid(with: transaction)
        
        getTransactionsPerMonth()
    }
    
    func delete(transaction: Transaction) {
        repository?.remove(with: transaction)
        
        getTransactionsPerMonth()
    }
    
    func changeSlash(transaction: Transaction) {
        repository?.changeSlash(with: transaction)
        
        getTransactionsPerMonth()
    }
    
    func edit(with transaction: Transaction) {
        selectedTransaction = transaction
        goToEditView = true
    }
}
