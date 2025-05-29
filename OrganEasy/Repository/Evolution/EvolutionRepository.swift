//
//  EvolutionRepository.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//

import CoreData

class EvolutionRepository {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Access Methods
    
    func fetchAll() -> [Evolution] {
        let request: NSFetchRequest<Evolution> = Evolution.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Evolution.bank?.name, ascending: false)
        ]
        
        do {
            let banks = try context.fetch(request)
            
            return banks
        } catch {
            print("Error fetching transactions: \(error)")
            return []
        }
    }
    
    func add(_ dto: EvolutionDTO) {
        let evolution = Evolution(context: context)
        evolution.id = dto.id
        evolution.date = dto.date
        evolution.value = dto.value
        evolution.bank = dto.bank
        
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
