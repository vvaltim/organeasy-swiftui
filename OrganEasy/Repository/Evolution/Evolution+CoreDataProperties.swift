//
//  Evolution+CoreDataProperties.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//
//

import Foundation
import CoreData


extension Evolution {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Evolution> {
        return NSFetchRequest<Evolution>(entityName: "Evolution")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var value: Double
    @NSManaged public var date: Date?
    @NSManaged public var bank: Bank?

}

//// MARK: Generated accessors for bank
//extension Evolution {
//
//    @objc(addBankObject:)
//    @NSManaged public func addToBank(_ value: Bank)
//
//    @objc(removeBankObject:)
//    @NSManaged public func removeFromBank(_ value: Bank)
//
//    @objc(addBank:)
//    @NSManaged public func addToBank(_ values: NSSet)
//
//    @objc(removeBank:)
//    @NSManaged public func removeFromBank(_ values: NSSet)
//
//}

extension Evolution : Identifiable {

}
