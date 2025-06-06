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
    
    private let repository: TransactionRepositoryProtocol
    private let onClose: () -> Void
    
    @Published public var description: String = ""
    @Published public var dueDate: Date = Date()
    @Published public var amount: String = "R$ 0,00"
    @Published public var isIncome: Bool = false
    
    var isDissabledSaveButton: Bool {
        description.isEmpty
    }
    
    // MARK: - Initializer
    
    init (repository: TransactionRepositoryProtocol, onClose: @escaping () -> Void) {
        self.repository = repository
        self.onClose = onClose
    }
    
    // MARK: - Methods
    
    func saveAction() {
        let dto = TransactionDTO(
            isIncome: isIncome,
            descriptionText: description,
            amount: amount.concurrenceToDouble(),
            dueDate: dueDate,
            isSlash: false  // Colocar um campo na tela para isso
        )
        
        repository.add(with: dto)
        
        onClose()
    }
}
