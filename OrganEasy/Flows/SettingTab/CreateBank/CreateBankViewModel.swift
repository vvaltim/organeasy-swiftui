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
    
    private let repository: BankRepository
    private let onClose: () -> Void
    
    @Published public var name: String = ""
    
    var isDissabledSaveButton: Bool {
        name.isEmpty
    }
    
    // MARK: - Initializer
    
    init (repository: BankRepository, onClose: @escaping () -> Void) {
        self.repository = repository
        self.onClose = onClose
    }
    
    // MARK: - Methods
    
    func saveAction() {
        let dto = BankDTO(
            id: UUID(),
            name: name,
            isHidden: false
        )
        
        repository.add(dto)
        
        onClose()
    }
}
