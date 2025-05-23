//
//  Transaction+CoreDataClass.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 22/05/25.
//
//

import Foundation
import CoreData

@objc(Transaction)
public class Transaction: NSManagedObject {

    func getMonthTitle() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "pt_BR")
        dateFormatter.dateFormat = "MMMM 'de' yyyy"
        
        return dateFormatter.string(from: self.dueDate).capitalized
    }
    
    func add(transaction: Transaction) {
        
    }
}
