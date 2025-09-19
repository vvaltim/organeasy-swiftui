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
    
    func getTransaction() -> String {
        return "isIncome: \(isIncome)\ndescriptionText: \(descriptionText)\namount: \(amount)\ndueDate: \(dueDate)\nisSlash: \(isSlash)"
    }
}
