//
//  TransactionRepository.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 23/05/25.
//

import CoreData

protocol TransactionRepositoryProtocol {
    func fetchAll() -> [Transaction]
    func add(with dto: TransactionDTO)
    func remove(with transaction: Transaction)
    func markToPaid(with transaction: Transaction)
    func changeSlash(with transaction: Transaction)
    func saveEdit()
    func getById(_ id: UUID) -> Transaction?
}

class TransactionRepository: TransactionRepositoryProtocol {
        
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
    
    func add(with dto: TransactionDTO) {
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.descriptionText = dto.descriptionText
        transaction.dueDate = dto.dueDate
        transaction.amount = dto.amount
        transaction.isIncome = dto.isIncome
        transaction.isSlash = dto.isSlash
        
        save()
    }
    
    func remove(with transaction: Transaction) {
        context.delete(transaction)
        
        save()
    }
    
    func markToPaid(with transaction: Transaction) {
        transaction.paymentDate = Date()
        
        save()
    }
    
    func changeSlash(with transaction: Transaction) {
        transaction.isSlash.toggle()
        
        save()
    }
    
    func saveEdit() {
        save()
    }
    
    func getById(_ id: UUID) -> Transaction? {
        let request = Transaction.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching transactions: \(error)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func save() {
        do {
            try context.save()
        } catch {
            print("Erro ao salvar a transação: \(error)")
        }
    }
}
