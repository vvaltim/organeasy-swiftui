//
//  MonthlyEntry.swift
//  MyApp
//
//  Created by Walter Vânio dos Reis Júnior on 09/06/26.
//
//

import Foundation
import SwiftData

@Model
final class MonthlyEntry {

    var id: UUID = UUID()

    var name: String = ""

    var amount: Double = 0
    
    var referenceMonth: String = ""

    var dueDate: Date = Date()
    
    var type: EntryType = EntryType.expense
    
    var paymentDate: Date?
    
    init(
        name: String,
        amount: Double,
        referenceMonth: String,
        dueDate: Date,
        type: EntryType
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.referenceMonth = referenceMonth
        self.dueDate = dueDate
        self.type = type
    }
}
