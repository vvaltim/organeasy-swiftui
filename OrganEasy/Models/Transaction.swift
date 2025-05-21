//
//  Transaction.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import Foundation

struct Transaction {
    var id: UUID
    var description: String
    var dueDate: Date
    var paymentDate: Date?
    var amount: Double
    var isIncome: Bool
}
