//
//  CreateEvolutionViewModel.swift
//  OrganEasy
//
//  Created by Walter Vanio dos Reis Junior on 29/05/25.
//

import Foundation
import SwiftUI
import CoreData

class CreateEvolutionViewModel: ObservableObject {
    
    // MARK: - Variables
    
    private var bankRepository: BankRepositoryProtocol?
    private var evolutionRepository: EvolutionRepositoryProtocol?
    
    @Published public var bankList: [Bank] = []
    @Published public var selectedBank: Int = 0
    @Published public var amount: String = 0.0.toBRL()
    @Published public var date: Date = Date()
    
    func setupProvider(with provider: RepositoryProvider) {
        self.bankRepository = provider.bankRepository
        self.evolutionRepository = provider.evolutionRepository
    }
    
    func fetchBanks() {
        bankList = bankRepository?.fetchAll() ?? []
    }
    
    func saveEvolution() {
        let dto = EvolutionDTO(
            id: UUID(),
            value: amount.concurrenceToDouble(),
            date: date,
            bank: bankList[selectedBank]
        )
        
        evolutionRepository?.add(with: dto)
    }
}
