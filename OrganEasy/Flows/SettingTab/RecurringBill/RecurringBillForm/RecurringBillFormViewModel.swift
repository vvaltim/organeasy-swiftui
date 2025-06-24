//
//  RecurringBillFormViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 24/06/25.
//

import Foundation

class RecurringBillFormViewModel: ObservableObject {
    
    // MARK: - Variables
    
    private var repository: RecurringBillRepositoryProtocol?
    var recurringBill: RecurringBill?
    
    @Published public var description: String = ""
    @Published public var dueDate: Date = Date()
    @Published public var amount: Double = 0.0
    @Published public var isIncome: Bool = false
    
    var isDissabledSaveButton: Bool {
        description.isEmpty
    }
    
    // MARK: - Methods
    
    func setupProvider(with provider: RepositoryProvider) {
        repository = provider.recurringBillRepository
    }
    
    func setupRecurringBill(with id: UUID?) {
        guard let id else {
            return
        }
        
        self.recurringBill = repository?.getById(id)
        
        description = recurringBill?.name ?? ""
        dueDate = recurringBill?.dueDate ?? Date()
        amount = recurringBill?.amount ?? 0.0
    }
    
    func saveAction() {
        guard let recurringBill else {
            let dto = RecurringBillDTO(
                name: description,
                amount: amount,
                dueDate: dueDate
            )
            
            repository?.add(with: dto)
            return
        }
        
        recurringBill.name = description
        recurringBill.amount = amount
        recurringBill.dueDate = dueDate
        
        repository?.saveEdit()
    }
}
