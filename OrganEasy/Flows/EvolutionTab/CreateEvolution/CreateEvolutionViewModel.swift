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
    
    private let bankARepository: BankRepository
    private let evolutionRepository: EvolutionRepository
    
    private let onClose: () -> Void
    
    @Published public var bankList: [Bank] = []
    @Published public var selectedBank: Int = 0
    @Published public var amount: String = "R$ 0,00"
    
    init(bankRepository: BankRepository, evolutionRepository: EvolutionRepository, onClose: @escaping () -> Void) {
        self.bankARepository = bankRepository
        self.evolutionRepository = evolutionRepository
        self.onClose = onClose
        
        self.bankList = bankRepository.fetchAll()
    }
    
    func saveEvolution() {
        let dto = EvolutionDTO(
            id: UUID(),
            value: amount.concurrenceToDouble(),
            date: Date(),
            bank: bankList[selectedBank]
        )
        
        evolutionRepository.add(dto)
        
        onClose()
    }
}
