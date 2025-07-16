//
//  HomeViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI
import CoreData
import UserNotifications

class HomeViewModel: ObservableObject {
    
    // MARK: - Variables
    
    private var repository: TransactionRepositoryProtocol?
    
    // MARK: - Items View
    
    @Published var transactions: [Transaction] = []
    @Published var groupedByMonth: [String: [Transaction]] = [:]
    
    // MARK: - Navigation
    
    @Published var goToTransactionView = false
    @Published var goToTransactionDetailView = false
    
    // MARK: - Computed Variable
    
    var firstTransactionPerMonth: [Transaction] {
        groupedByMonth.values.compactMap {
            $0.first
        }
    }
    
    var groupedByMonthSorted: [(String, [Transaction])] {
        groupedByMonth
            .map { (key, value) in
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/yyyy"
                let date = formatter.date(from: key) ?? Date.distantPast
                return (key, value, date)
            }
            .sorted {
                $0.2 > $1.2
            }
            .map {
                ($0.0, $0.1)
            }
    }
    
    var firstTransactionPerMonthSorted: [Transaction] {
        groupedByMonthSorted.compactMap { $0.1.first }
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
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            // Aqui você pode tratar o resultado, se quiser
        }
    }
    
    // MARK: - Private Methods
    
    private func groupedByMonthTransactions() {
        let grouped = Dictionary(grouping: transactions) { transaction in
            return transaction.dueDate.formatToMonthYear()
        }
        
        groupedByMonth = grouped.mapValues {
            $0.sorted {
                $0.dueDate > $1.dueDate
            }
        }
    }
}
