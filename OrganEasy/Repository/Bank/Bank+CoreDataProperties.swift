//
//  Bank+CoreDataProperties.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//
//

import Foundation
import CoreData


extension Bank {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Bank> {
        return NSFetchRequest<Bank>(entityName: "Bank")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var isHidden: Bool
    @NSManaged public var name: String?

}

extension Bank : Identifiable {

}
