//
//  EvolutionRepository.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//

import CoreData

protocol EvolutionRepositoryProtocol {
    func fetchAll() -> [Evolution]
    func add(with dto: EvolutionDTO)
    func delete(with evolution: Evolution)
    func getById(with id: UUID) -> Evolution?
}

class EvolutionRepository: EvolutionRepositoryProtocol {
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
    
    func add(with dto: EvolutionDTO) {
        let evolution = Evolution(context: context)
        evolution.id = dto.id
        evolution.date = dto.date
        evolution.value = dto.value
        evolution.bank = dto.bank
        evolution.addWithIA = dto.addWithIA
        
        save()
    }
    
    func delete(with evolution: Evolution) {
        context.delete(evolution)
        
        save()
    }
    
    func getById(with id: UUID) -> Evolution? {
        let request = Evolution.fetchRequest()
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
    
    func save() {
        do {
            try context.save()
        } catch {
            print("Erro ao salvar a transação: \(error)")
        }
    }
}
