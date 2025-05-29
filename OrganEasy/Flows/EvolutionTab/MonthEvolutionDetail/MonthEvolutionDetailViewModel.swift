//
//  MonthEvolutionDetailViewModel.swift
//  OrganEasy
//
//  Created by Walter Vanio dos Reis Junior on 29/05/25.
//

import Foundation

class MonthEvolutionDetailViewModel: ObservableObject {
    
    // MARK: - Variables
    
    private let repository: EvolutionRepository
    
    @Published var evolutions: [Evolution] = []
    @Published var month: String = ""
    
    var total: Double {
        evolutions.reduce(0, { $0 + $1.value })
    }
    
    // MARK: - Init
    
    init(repository: EvolutionRepository, month: String) {
        self.repository = repository
        self.month = month
        
        getEvolutionsPerMonth()
    }
    
    // MARK: - Public Functions

    
    
    // MARK: - Private Functions
    
    private func getEvolutionsPerMonth() {
        let allEvaluations = repository.fetchAll()
        
        evolutions = allEvaluations.filter {
            $0.date?.formatToMonthYear() == month
        }
        print("Quantidade de evoluções: \(evolutions.count)")
        
//        objectWillChange.send()
    }
}
