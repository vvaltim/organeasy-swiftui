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
    var addWithIA: Bool
    var paymentDate: Date?
    
    init(
        isIncome: Bool,
        descriptionText: String,
        amount: Double,
        dueDate: Date,
        isSlash: Bool,
        addWithIA: Bool = false,
        paymentDate: Date? = nil
    ) {
        self.isIncome = isIncome
        self.descriptionText = descriptionText
        self.amount = amount
        self.dueDate = dueDate
        self.isSlash = isSlash
        self.addWithIA = addWithIA
        self.paymentDate = paymentDate
    }
    
    func getTransaction() -> String {
        return "isIncome: \(isIncome)\ndescriptionText: \(descriptionText)\namount: \(amount)\ndueDate: \(dueDate)\nisSlash: \(isSlash)"
    }
}
