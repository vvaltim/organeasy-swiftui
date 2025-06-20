//
//  HomeViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI
import CoreData

class HomeViewModel: ObservableObject {
    
    // MARK: - Variables
    
    private var repository: TransactionRepositoryProtocol?
    
    // MARK: - Items View
    
    @Published var transactions: [Transaction] = []
    @Published var groupedByMonth: [String: [Transaction]] = [:]
    
    // MARK: - Navigation
    
    @Published var goToTransactionView = false
    @Published var goToTransactionDetailView = false
    
    var firstTransactionPerMonth: [Transaction] {
        groupedByMonth.values.compactMap {
            $0.first
        }
    }
    
    // MARK: - Public Methods
    
    func setupProvider(with provider: RepositoryProvider) {
        repository = provider.transactionRepository
    }
    
    func addButtonTapped() {
        goToTransactionView = true
    }
    
    func fetchTransactions() {
        transactions = repository?.fetchAll() ?? []
        
        groupedByMonthTransactions()
    }
    
    // MARK: - Private Methods
    
    private func groupedByMonthTransactions() {
        
        groupedByMonth = Dictionary(grouping: transactions) { transaction in
            return transaction.dueDate.formatToMonthYear()
        }
    }
}
