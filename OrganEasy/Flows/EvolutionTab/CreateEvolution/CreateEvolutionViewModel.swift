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
    
    @Published public var bankList: [Bank] = []
    @Published public var selectedBank: Int = 0
    @Published public var value: String = 0.0.toBRL()
    
    init(bankRepository: BankRepository, evolutionRepository: EvolutionRepository) {
        self.bankARepository = bankRepository
        self.evolutionRepository = evolutionRepository
        
        self.bankList = bankRepository.fetchAll()
    }
    
    
}
