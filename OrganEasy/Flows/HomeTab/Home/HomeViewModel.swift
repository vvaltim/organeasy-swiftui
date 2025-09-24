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
    
    // MARK: - Items View
    
    @Published var transactions: [Transaction] = []
    @Published var months: [Date] = []
    
    // MARK: - Navigation
    
    @Published var goToTransactionView = false
    @Published var goToTransactionDetailView = false
    
    // MARK: - Computed Variable
    
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
        transactions = allTransactions.filter { transaction in
            let components = calendar.dateComponents([.year, .month], from: transaction.dueDate)
            let nowComponents = calendar.dateComponents([.year, .month], from: now ?? Date())
            return components.year == nowComponents.year && components.month == nowComponents.month
        }
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
}
