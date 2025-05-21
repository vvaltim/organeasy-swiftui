//
//  HomeViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var goToTransactionView = false
    
    func addButtonTapped() {
        goToTransactionView = true
    }
}
