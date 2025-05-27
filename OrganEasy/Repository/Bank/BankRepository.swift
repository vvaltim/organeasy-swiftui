//
//  BankRepository.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//

import CoreData

class BankRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Access Methods
    
    func fetchAll() -> [Bank] {
        let request: NSFetchRequest<Bank> = Bank.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Bank.isHidden, ascending: false),
            NSSortDescriptor(keyPath: \Bank.name, ascending: false)
        ]
        
        do {
            let banks = try context.fetch(request)
            
            return banks
        } catch {
            print("Error fetching transactions: \(error)")
            return []
        }
    }
    
    func add(_ dto: BankDTO) {
        let bank = Bank(context: context)
        bank.id = dto.id
        bank.name = dto.name
        bank.isHidden = dto.isHidden
        
        save()
    }
    
    func changeVisibility(_ bank: Bank) {
        bank.isHidden.toggle()
        
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

