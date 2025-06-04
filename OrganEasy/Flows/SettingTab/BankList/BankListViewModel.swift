//
//  BankListViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//

import SwiftUI

class BankListViewModel: ObservableObject {
    
    // MARK: - Variables
    
    let repository: BankRepositoryProtocol
    
    @Published var goToCreateBankView = false
    
    // MARK: - Items View
    
    @Published var banks: [Bank] = []
    
    // MARK: - Initializer
    
    init(repository: BankRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK:  Public Methods
    
    func fetchAll() {
        banks = repository.fetchAll()
    }
    
    func changeVisibility(_ bank : Bank) {
        repository.changeVisibility(with: bank)
        
        fetchAll()
    }
    
    func addButtonTapped() {
        goToCreateBankView = true
    }
}
