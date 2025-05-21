//
//  TransactionViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import Foundation
import SwiftUI

class TransactionViewModel: ObservableObject {
    
    // MARK: - Variables
    
    @Published public var description: String = ""
    @Published public var dueDate: Date = Date()
    @Published public var amount: String = "R$ 0,00"
    @Published public var isIncome: Bool = false
    
    var isDissabledSaveButton: Bool {
        description.isEmpty
    }
    
    // MARK: - Methods
    
    func validadeTransaction() {
        // salvar o valor
    }
}
