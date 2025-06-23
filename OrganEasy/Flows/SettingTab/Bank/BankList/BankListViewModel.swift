//
//  BankListViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//

import SwiftUI

class BankListViewModel: ObservableObject {
    
    // MARK: - Variables
    
    private var repository: BankRepositoryProtocol?
    
    @Published var goToCreateBankView = false
    
    // MARK: - Items View
    
    @Published var banks: [Bank] = []
    
    // MARK:  Public Methods
    
    func setup(with provider: RepositoryProvider) {
        repository = provider.bankRepository
    }
    
    func fetchAll() {
        banks = repository?.fetchAll() ?? []
    }
    
    func changeVisibility(_ bank : Bank) {
        repository?.changeVisibility(with: bank)
        
        fetchAll()
    }
    
    func addButtonTapped() {
        goToCreateBankView = true
    }
}
