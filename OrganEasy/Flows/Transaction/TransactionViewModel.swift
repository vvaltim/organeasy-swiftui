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
    
    private let context: NSManagedObjectContext
    
    @Published public var description: String = ""
    @Published public var dueDate: Date = Date()
    @Published public var amount: String = "R$ 0,00"
    @Published public var isIncome: Bool = false
    
    var isDissabledSaveButton: Bool {
        description.isEmpty
    }
    
    // MARK: - Initializer
    
    init (context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Methods
    
    func saveAction() {
        let transaction = Transaction(context: context)
        transaction.id = UUID()
        transaction.descriptionText = description
        transaction.dueDate = dueDate
        transaction.amount = amount.concurrenceToDouble()
        transaction.isIncome = isIncome
        
        do {
            try context.save()
            
            // fechar a tela
        } catch {
            print("Erro ao salvar a transação: \(error)")
        }
    }
}
