//
//  EvolutionRouter.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 18/08/25.
//

import SwiftUI

enum EvolutionRouter: Hashable {
    case evolution(UUID?)
    case month(String)
}

class EvolutionNavigationManager: ObservableObject {
    @Published var path = NavigationPath()
}
