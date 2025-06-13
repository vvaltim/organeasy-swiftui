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
    
    private var repository: TransactionRepositoryProtocol?
    var transaction: Transaction?
    
    @Published public var description: String = ""
    @Published public var dueDate: Date = Date()
    @Published public var amount: String = 0.0.toBRL()
    @Published public var isIncome: Bool = false
    
    var isDissabledSaveButton: Bool {
        description.isEmpty
    }
    
    // MARK: - Methods
    
    func setupProvider(with provider: RepositoryProvider) {
        repository = provider.transactionRepository
    }
    
    func setupTransaction(with id: UUID?) {
        guard let id else {
            return
        }
        
        self.transaction = repository?.getById(id)
        
        print(transaction?.descriptionText ?? "")
        
        description = transaction?.descriptionText ?? ""
        dueDate = transaction?.dueDate ?? Date()
//        amount = transaction?.amount.toBRL() ?? 0.0.toBRL() // ver como configurar o campo de texto aqui
        isIncome = transaction?.isIncome ?? false
    }
    
    func saveAction() {
        guard let transaction else {
            let dto = TransactionDTO(
                isIncome: isIncome,
                descriptionText: description,
                amount: amount.concurrenceToDouble(),
                dueDate: dueDate,
                isSlash: false
            )
            
            repository?.add(with: dto)
            return
        }
        
        transaction.isIncome = isIncome
        transaction.descriptionText = description
        transaction.amount = amount.concurrenceToDouble()
        transaction.dueDate = dueDate
        
        repository?.saveEdit()
    }
}
