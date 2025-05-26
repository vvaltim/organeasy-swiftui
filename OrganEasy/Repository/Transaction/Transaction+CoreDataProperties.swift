//
//  Transaction+CoreDataProperties.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 22/05/25.
//
//

import Foundation
import CoreData

extension Transaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Transaction> {
        return NSFetchRequest<Transaction>(entityName: "Transaction")
    }

    @NSManaged public var amount: Double
    @NSManaged public var descriptionText: String
    @NSManaged public var dueDate: Date
    @NSManaged public var id: UUID
    @NSManaged public var isIncome: Bool
    @NSManaged public var paymentDate: Date?
    @NSManaged public var isSlash: Bool

}

extension Transaction : Identifiable {

}
