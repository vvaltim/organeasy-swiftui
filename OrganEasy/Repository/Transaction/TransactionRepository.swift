//
//  TransactionRepository.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 23/05/25.
//

import CoreData

class TransactionRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Access Methods
    
    func fetchAll() -> [Transaction] {
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Transaction.dueDate, ascending: false)
        ]
        
        do {
            let transactions = try context.fetch(request)
            
            return transactions
        } catch {
            print("Error fetching transactions: \(error)")
            return []
        }
    }
    
    func add(_ dto: TransactionDTO) {
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.descriptionText = dto.descriptionText
        transaction.dueDate = dto.dueDate
        transaction.amount = dto.amount
        transaction.isIncome = dto.isIncome
        transaction.isSlash = dto.isSlash
        
        save()
    }
    
    func remove(_ transaction: Transaction) {
        context.delete(transaction)
        
        save()
    }
    
    func markToPaid(_ transaction: Transaction) {
        transaction.paymentDate = Date()
        
        save()
    }
    
    func changeSlash(_ transaction: Transaction) {
        transaction.isSlash.toggle()
        
        save()
    }
    
    // MARK: - Private Methods
    
    func save() {
        do {
            try context.save()
        } catch {
            print("Erro ao salvar a transação: \(error)")
        }
    }
}
