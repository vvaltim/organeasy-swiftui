import SwiftData
import Foundation

public struct OrganEasyModelContainer {
    
    // MARK: - Ambiente para Preview
    
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
            
            // MARK: Mock das despesas
            
            for index in 0..<10 {
                let indexNumber = index + 1
                
                var newDate = Date()
                var comps = Calendar.current.dateComponents([.year, .month], from: newDate)
                if let day = comps.day { comps.day = day + indexNumber }
                let date = Calendar.current.date(from: comps) ?? newDate
                var referenceMonth = date.getReferenceMonth()
                
                let monthly = MonthlyEntry(
                    name: "Conta \(indexNumber)",
                    amount: 3.33 * (Double(indexNumber) + 1.0),
                    referenceMonth: referenceMonth,
                    dueDate: Date(),
                    type: .expense
                )
                context.insert(monthly)
            }
            
            // MARK: Mock da entrada
            
            let income = MonthlyEntry(
                name: "Salário",
                amount: 1234.56,
                referenceMonth: Date().getReferenceMonth(),
                dueDate: Date(),
                type: .income
            )
            context.insert(income)
            
            try context.save()
            
            return container
            
        } catch {
            fatalError("Preview container failed: \(error)")
        }
    }
    
    // MARK: - Ambiente produtivo
    
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
