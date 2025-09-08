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
    
    @Published var monthsWithTotal: [(Date, Double)] = []

    var allEvolution = [Evolution]()
    
    // MARK: Chart
    
    var chartData: [TestValues] {
        var test: [TestValues] = []
        
        for item in monthsWithTotal {
            let item = TestValues(
                month: item.0.formatTo(dateFormat: "MMM/yy"),
                value: item.1
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
        allEvolution = repository?.fetchAll() ?? []
        
        monthsWithTotal = allMonthsForFilter()
    }
    
    // MARK: - Private Methods
    
    private func allMonthsForFilter() -> [(Date, Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: allEvolution) { (evolution) -> Date in
            guard let date = evolution.date else { return Date() }
            let components = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: components)!
        }
        
        let result = grouped.map { (key, evolutions) -> (Date, Double) in
            let total = evolutions.reduce(0) { $0 + $1.value }
            return (key, total)
        }
        
        return result.sorted { $0.0 < $1.0 }
    }
}
