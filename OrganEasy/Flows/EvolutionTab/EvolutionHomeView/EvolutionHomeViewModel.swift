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
    
    private let repository: EvolutionRepository
    
    // MARK: - Navigation
    
    @Published var goToCreateEvolution = false
    @Published var goToDetailEvolution = false
    var selectedMonth = ""
    
    // MARK: - ItemView
    
    @Published var groupedByMonth: [String: [Evolution]] = [:]
    var firstEvolutionPerMonth: [Evolution] {
        groupedByMonth.values.compactMap {
            $0.first
        }
    }
    
    // MARK: - Init
    
    init(repository: EvolutionRepository) {
        self.repository = repository
        
        fetchAll()
    }
    
    // MARK: - Public Functions
    
    func openCreateEvolution() {
        goToCreateEvolution = true
    }
    
    func closeCreateEvolution() {
        goToCreateEvolution = false
        
        fetchAll()
    }
    
    func openDetailsEvolution(_ evolution: Evolution) {
        goToDetailEvolution = true
        selectedMonth = evolution.date?.formatToMonthYear() ?? ""
    }
    
    func fetchAll() {
        let allEvolution = repository.fetchAll()
        
        groupedByMonth = Dictionary(grouping: allEvolution) { evolution in
            return evolution.date?.formatToMonthYear() ?? ""
        }
    }
    
}
