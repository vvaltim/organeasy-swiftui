//
//  ModelContainer.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 09/06/26.
//

import SwiftData
import Foundation

public struct OrganEasyModelContainer {
    
    static var preview: ModelContainer {
        
        do {
            
            let schema = Schema([
                MonthlyEntry.self,
                RecurringEntryTemplate.self
            ])
            
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            
            let container = try ModelContainer(
                for: schema,
                configurations: configuration
            )
            
            let context = ModelContext(container)
            
            // Dados fake
//            let template = RecurringEntryTemplate(
//                id: UUID(),
//                dueDay: Int,
//                enabled: <#T##Bool#>,
//                name: <#T##String#>,
//                type: <#T##EntryType#>
//            )
            
//            context.insert(template)
            
            try context.save()
            
            return container
            
        } catch {
            fatalError("Preview container failed: \(error)")
        }
    }
    
    static let shared: ModelContainer = {
        
        do {
            
            let schema = Schema([
                MonthlyEntry.self,
                RecurringEntryTemplate.self
            ])
            
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        
    }()
}
