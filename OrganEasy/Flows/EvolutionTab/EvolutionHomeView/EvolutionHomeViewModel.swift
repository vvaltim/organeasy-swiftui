//
//  EvolutionHomeViewModel.swift
//  OrganEasy
//
//  Created by Walter Vanio dos Reis Junior on 29/05/25.
//

import Foundation
import SwiftUI
import CoreData

class EvolutionHomeViewModel: ObservableObject {
    
    // MARK: - Variables
    
    private var repository: EvolutionRepositoryProtocol?
    
    // MARK: - ItemView
    
    @Published var groupedByMonth: [String: [Evolution]] = [:]
    var firstEvolutionPerMonth: [Evolution] {
        groupedByMonth.values.compactMap {
            $0.first
        }
    }
    
    // MARK: Chart
    
    var chartData: [TestValues] {
        var test: [TestValues] = []
        
        for evolutionKey in groupedByMonth.keys {
            let month = groupedByMonth[evolutionKey]?.first?.date?.formatTo(dateFormat: "MMM/yy") ?? .init()
            let value = groupedByMonth[evolutionKey]?.reduce(0) { $0 + $1.value } ?? 0.0
            
            let item = TestValues(
                month: month,
                value: value
            )
            
            test.append(item)
        }
        
        return test
    }
    
    // MARK: - Public Functions
    
    func setupProvider(with provider: RepositoryProvider) {
        repository = provider.evolutionRepository
    }
    
    func fetchAll() {
        let allEvolution = repository?.fetchAll() ?? []
        
        groupedByMonth = Dictionary(grouping: allEvolution) { evolution in
            return evolution.date?.formatToMonthYear() ?? ""
        }
    }
    
    func getTotalByMonth(month: String) -> Double {
        groupedByMonth[month]?.reduce(0) { $0 + $1.value } ?? 0.0
    }
}
