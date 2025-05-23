//
//  TransactionViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import Foundation
import SwiftUI
import CoreData

class TransactionViewModel: ObservableObject {
    
    // MARK: - Variables
    
    private let repository: TransactionRepository
    private let onClose: () -> Void
    
    @Published public var description: String = ""
    @Published public var dueDate: Date = Date()
    @Published public var amount: String = "R$ 0,00"
    @Published public var isIncome: Bool = false
    
    var isDissabledSaveButton: Bool {
        description.isEmpty
    }
    
    // MARK: - Initializer
    
    init (repository: TransactionRepository, onClose: @escaping () -> Void) {
        self.repository = repository
        self.onClose = onClose
    }
    
    // MARK: - Methods
    
    func saveAction() {
        let dto = TransactionDTO(
            isIncome: isIncome,
            descriptionText: description,
            amount: amount.concurrenceToDouble(),
            dueDate: dueDate
        )
        
        repository.add(dto)
        
        onClose()
    }
}
