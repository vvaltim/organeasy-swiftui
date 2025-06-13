//
//  DummyRepositoryProvider.swift
//  OrganEasy
//
//  Created by Walter Vanio dos Reis Junior on 04/06/25.
//

import Foundation

final class DummyRepositoryProvider: ObservableObject {
    let transactionRepository: TransactionRepositoryProtocol = DummyTransactionRepository()
    let evolutionRepository: EvolutionRepositoryProtocol = DummyEvolutionRepository()
    let bankRepository: BankRepositoryProtocol = DummyBankRepository()
}

class DummyTransactionRepository: TransactionRepositoryProtocol {
    func getById(_ id: UUID) -> Transaction? {
        return nil
    }
    
    func saveEdit() {
        /* Intentionally unimplemented */
    }
    
    func add(with dto: TransactionDTO) {
        /* Intentionally unimplemented */
    }
    
    func remove(with transaction: Transaction) {
        /* Intentionally unimplemented */
    }
    
    func markToPaid(with transaction: Transaction) {
        /* Intentionally unimplemented */
    }
    
    func changeSlash(with transaction: Transaction) {
        /* Intentionally unimplemented */
    }
    
    func fetchAll() -> [Transaction] {
        return []
    }
}

class DummyEvolutionRepository: EvolutionRepositoryProtocol {
    
    func fetchAll() -> [Evolution] {
        return []
    }
    
    func add(with dto: EvolutionDTO) {
        /* Intentionally unimplemented */
    }
    
}

class DummyBankRepository: BankRepositoryProtocol {
    func fetchAll() -> [Bank] {
        return []
    }
    
    func add(with dto: BankDTO) {
        /* Intentionally unimplemented */
    }
    
    func changeVisibility(with dto: Bank) {
        /* Intentionally unimplemented */
    }
}
