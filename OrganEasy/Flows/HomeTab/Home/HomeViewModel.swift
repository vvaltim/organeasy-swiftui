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
    private var allTransactions: [Transaction] = []
    private var selectedFilter: Date?
    
    // MARK: - Items View
    
    @Published var transactions: [Transaction] = []
    @Published var months: [Date] = []
    
    // MARK: - Navigation
    
    @Published var goToTransactionView = false
    @Published var goToTransactionDetailView = false
    
    // MARK: Computable Variable
    
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
    
    func addButtonTapped() {
        goToTransactionView = true
    }
    
    func fetchTransactions() {
        allTransactions = repository?.fetchAll() ?? []
        months = allMonthsForFilter()
        
        filterPerMonth(with: nil)
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            // Aqui você pode tratar o resultado, se quiser
        }
    }
    
    func filterPerMonth(with month: Date?) {
        let calendar = Calendar.current
        let now = month ?? months.first
        selectedFilter = now
        transactions = allTransactions.filter { transaction in
            let components = calendar.dateComponents([.year, .month], from: transaction.dueDate)
            let nowComponents = calendar.dateComponents([.year, .month], from: now ?? Date())
            return components.year == nowComponents.year && components.month == nowComponents.month
        }
    }
    
    func markToPaid(transaction: Transaction) {
        repository?.markToPaid(with: transaction)
        
        refreshData()
    }
    
    func delete(transaction: Transaction) {
        repository?.remove(with: transaction)
        
        refreshData()
    }
    
    func changeSlash(transaction: Transaction) {
        repository?.changeSlash(with: transaction)
        
        refreshData()
    }
    
    // MARK: - Private Methods
    
    private func allMonthsForFilter() -> [Date] {
        var allDates: [Date] = []
        
        for transaction in allTransactions {
            allDates.append(transaction.dueDate)
        }
        
        var seen = Set<String>()
        let calendar = Calendar.current
        return allDates.filter { date in
            let components = calendar.dateComponents([.year, .month], from: date)
            let key = "\(components.year!)-\(components.month!)"
            if seen.contains(key) {
                return false
            } else {
                seen.insert(key)
                return true
            }
        }
    }
    
    private func refreshData() {
        allTransactions = repository?.fetchAll() ?? []
        
        filterPerMonth(with: selectedFilter)
    }
}
