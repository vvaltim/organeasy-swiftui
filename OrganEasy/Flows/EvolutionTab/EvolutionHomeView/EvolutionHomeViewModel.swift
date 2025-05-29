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
    
    // MARK: - Navigation
    
    @Published var goToCreateEvolution = false
    

    // MARK: - Public Functions
    
    func openCreateEvolution() {
        goToCreateEvolution = true
    }
    
}
