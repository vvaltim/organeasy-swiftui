//
//  MonthEvolutionDetailViewModel.swift
//  OrganEasy
//
//  Created by Walter Vanio dos Reis Junior on 29/05/25.
//

import Foundation

class MonthEvolutionDetailViewModel: ObservableObject {
    
    // MARK: - Variables
    
    private var repository: EvolutionRepositoryProtocol?
    
    @Published var evolutions: [Evolution] = []
    @Published var month: String = ""
    
    var total: Double {
        evolutions.reduce(0, { $0 + $1.value })
    }
    
    // MARK: - Public Functions

    func setupProvider(with provider: RepositoryProvider) {
        repository = provider.evolutionRepository
    }
    
    // MARK: - Private Functions
    
    func getEvolutionsPerMonth() {
        let allEvaluations = repository?.fetchAll() ?? []
        
        evolutions = allEvaluations.filter {
            $0.date?.formatToMonthYear() == month
        }
    }
}
