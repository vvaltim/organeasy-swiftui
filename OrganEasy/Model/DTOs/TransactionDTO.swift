//
//  TransactionDTO.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 23/05/25.
//

import Foundation

struct TransactionDTO: Codable {
    var isIncome: Bool
    var descriptionText: String
    var amount: Double
    var dueDate: Date
    var isSlash: Bool
    
    init(
        isIncome: Bool,
        descriptionText: String,
        amount: Double,
        dueDate: Date,
        isSlash: Bool
    ) {
        self.isIncome = isIncome
        self.descriptionText = descriptionText
        self.amount = amount
        self.dueDate = dueDate
        self.isSlash = isSlash
    }
    
    func getTransaction() -> String {
        return "isIncome: \(isIncome)\ndescriptionText: \(descriptionText)\namount: \(amount)\ndueDate: \(dueDate)\nisSlash: \(isSlash)"
    }
}
