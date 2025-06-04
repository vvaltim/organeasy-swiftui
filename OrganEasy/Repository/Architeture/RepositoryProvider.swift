//
//  RepositoryProvider.swift
//  OrganEasy
//
//  Created by Walter Vanio dos Reis Junior on 04/06/25.
//

import Foundation
import CoreData

final class RepositoryProvider: ObservableObject {
    let transactionRepository: TransactionRepositoryProtocol
    let evolutionRepository: EvolutionRepositoryProtocol
    let bankRepository: BankRepositoryProtocol
    
    init(context: NSManagedObjectContext) {
        self.transactionRepository = TransactionRepository(context: context)
        self.evolutionRepository = EvolutionRepository(context: context)
        self.bankRepository = BankRepository(context: context)
    }
}
