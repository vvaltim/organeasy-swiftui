//
//  RecurrenceListViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 17/06/25.
//

import UIKit

class RecurringBillListViewModel: ObservableObject {
    
    private var repository: RecurringBillRepositoryProtocol?
    
    @Published var recurringBillList: [RecurringBill] = []
    
    func setup(with repository: RecurringBillRepositoryProtocol) {
        self.repository = repository
    }
    
    func fetchAll() {
        recurringBillList = (repository?.fetchAll() ?? [])
            .sorted { a, b in
                let dayA = a.dueDate.flatMap { Calendar.current.dateComponents([.day], from: $0).day } ?? Int.max
                let dayB = b.dueDate.flatMap { Calendar.current.dateComponents([.day], from: $0).day } ?? Int.max
                return dayA < dayB
            }
        
        for bill in recurringBillList {
            scheduleNotification(for: bill)
        }
    }
    
    // MARK: - Private Functions
    
    private func scheduleNotification(for bill: RecurringBill) {
        guard let id = bill.id?.uuidString,
              let name = bill.name,
              let dueDate = bill.dueDate else { return }
        
        var dateComponents = Calendar.current.dateComponents([.day], from: dueDate)
        dateComponents.hour = 9
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Conta \(name)"
        content.body = "Sua conta \(name) vence hoje!"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "recurring_bill_\(id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erro ao agendar notificação: \(error)")
            }
        }
    }
}
