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
    
    // MARK: - Private Methods
    
    private func save() {
        do {
            try context.save()
        } catch {
            print("Erro ao salvar a transação: \(error)")
        }
    }
}
