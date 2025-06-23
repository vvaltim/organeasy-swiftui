//
//  CreateBankViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//

import Foundation
import SwiftUI
import CoreData

class CreateBankViewModel: ObservableObject {
    
    // MARK: - Variables
    
    private var repository: BankRepositoryProtocol?
    
    @Published public var name: String = ""
    
    var isDissabledSaveButton: Bool {
        name.isEmpty
    }
    
    // MARK: - Methods
    
    func setup(with provider: RepositoryProvider) {
        repository = provider.bankRepository
    }
    
    func saveAction() {
        let dto = BankDTO(
            id: UUID(),
            name: name,
            isHidden: false
        )
        
        repository?.add(with: dto)
    }
}
