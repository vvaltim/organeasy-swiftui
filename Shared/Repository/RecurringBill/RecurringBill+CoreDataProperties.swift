//
//  RecurringBill+CoreDataProperties.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 23/06/25.
//
//

public import Foundation
public import CoreData


public typealias RecurringBillCoreDataPropertiesSet = NSSet

extension RecurringBill {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecurringBill> {
        return NSFetchRequest<RecurringBill>(entityName: "RecurringBill")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var amount: Double
    @NSManaged public var dueDate: Date?

}

extension RecurringBill : Identifiable {

}
