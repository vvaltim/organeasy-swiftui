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
    
    private let repository: TransactionRepository
    
    // MARK: - Items View
    
    @Published var transactions: [Transaction] = []
    @Published var groupedByMonth: [String: [Transaction]] = [:]
    
    // MARK: - Navigation
    
    @Published var goToTransactionView = false
    @Published var goToTransactionDetailView = false
    var detailItems: [Transaction] = []
    
    var firstTransactionPerMonth: [Transaction] {
        groupedByMonth.values.compactMap {
            $0.first
        }
    }
    
    // MARK: - Initializer
    
    init (repository: TransactionRepository) {
        self.repository = repository
        
        fetchTransactions()
    }
    
    // MARK: - Public Methods
    
    func addButtonTapped() {
        goToTransactionView = true
    }
    
    func detailItemTapped(_ month: String) {
        goToTransactionDetailView = true
        detailItems = groupedByMonth[month] ?? []
    }
    
    func fetchTransactions() {
        transactions = repository.fetchAll()
        
        groupedByMonthTransactions()
    }
    
    // MARK: - Private Methods
    
    private func groupedByMonthTransactions() {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "pt_BR")
        dateFormatter.dateFormat = "MMMM 'de' yyyy"
        
        groupedByMonth = Dictionary(grouping: transactions) { transaction in
            return dateFormatter.string(from: transaction.dueDate).capitalized
        }
    }
}
