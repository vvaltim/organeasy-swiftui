//
//  MonthTransactionDetailViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 22/05/25.
//

import SwiftUI

class MonthTransactionDetailViewModel: ObservableObject {
    
    @Published var transactions: [Transaction] = []
    @Published var month: String = ""
    
    init(transactions: [Transaction]) {
        self.transactions = transactions
        self.month = transactions.first?.getMonthTitle() ?? "Desconhecido"
    }
    
}
