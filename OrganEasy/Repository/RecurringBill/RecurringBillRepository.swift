//
//  RecurringBillRepository.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 23/06/25.
//

import CoreData

protocol RecurringBillRepositoryProtocol {
    func fetchAll() -> [RecurringBill]
    func add(with dto: RecurringBillDTO)
}

class RecurringBillRepository: RecurringBillRepositoryProtocol {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetchAll() -> [RecurringBill] {
        let request: NSFetchRequest<RecurringBill> = RecurringBill.fetchRequest()
        return (try? context.fetch(request)) ?? []
    }
    
    func add(with dto: RecurringBillDTO) {
        let bill = RecurringBill(context: context)
        bill.name = dto.name
        bill.amount = dto.amount
        bill.dueDate = dto.duyDate
        
        save()
    }
    
    // MARK: - Private Methods
    
    func save() {
        do {
            try context.save()
        } catch {
            print("Erro ao salvar a recorrencia: \(error)")
        }
    }
}
