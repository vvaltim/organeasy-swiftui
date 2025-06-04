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
    
    private let bankARepository: BankRepositoryProtocol
    private let evolutionRepository: EvolutionRepositoryProtocol
    
    private let onClose: () -> Void
    
    @Published public var bankList: [Bank] = []
    @Published public var selectedBank: Int = 0
    @Published public var amount: String = 0.0.toBRL()
    @Published public var date: Date = Date()
    
    init(bankRepository: BankRepositoryProtocol, evolutionRepository: EvolutionRepositoryProtocol, onClose: @escaping () -> Void) {
        self.bankARepository = bankRepository
        self.evolutionRepository = evolutionRepository
        self.onClose = onClose
        
        self.bankList = bankRepository.fetchAll()
    }
    
    func saveEvolution() {
        let dto = EvolutionDTO(
            id: UUID(),
            value: amount.concurrenceToDouble(),
            date: date,
            bank: bankList[selectedBank]
        )
        
        evolutionRepository.add(with: dto)
        
        onClose()
    }
}
