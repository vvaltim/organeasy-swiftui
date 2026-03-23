//
//  HomeRouter.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 12/06/25.
//

import SwiftUI
internal import Combine

enum HomeRouter: Hashable {
    case transaction(UUID?)
    case month(String)
}

class HomeNavigationManager: ObservableObject {
    @Published var path = NavigationPath()
}
