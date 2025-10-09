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
    @NSManaged public var addWithIA: Bool

}

extension Evolution : Identifiable {

}
