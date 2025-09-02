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
    private var evolution: Evolution?
    private var previewSelectedBank: Bank?
    
    @Published public var showBanklist: Bool = true
    @Published public var bankList: [Bank] = []
    @Published public var selectedBank: Int = 0
    @Published public var amount: Double = 0.0
    @Published public var date: Date = Date()
    
    func setupProvider(with provider: RepositoryProvider) {
        self.bankRepository = provider.bankRepository
        self.evolutionRepository = provider.evolutionRepository
    }
    
    func setupEvolution(with id: UUID?) {
        fetchBanks()
        
        guard let id else {
            return
        }
        
        self.evolution = evolutionRepository?.getById(with: id)
        
        date = evolution?.date ?? Date()
        amount = evolution?.value ?? 0.0
        previewSelectedBank = evolution?.bank
        showBanklist = false
    }
    
    func saveEvolution() {
        let dto = EvolutionDTO(
            id: UUID(),
            value: amount,
            date: date,
            bank: previewSelectedBank ?? bankList[selectedBank]
        )
        
        evolutionRepository?.add(with: dto)
    }
    
    private func fetchBanks() {
        bankList = bankRepository?.fetchAll() ?? []
    }
}
