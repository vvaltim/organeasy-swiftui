//
//  PersistenceController.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 22/05/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        // Adicionando 5 itens para mockar
        
        for i in 0..<5 {
                let transaction = Transaction(context: viewContext)
                transaction.id = UUID()
                transaction.descriptionText = "Transação \(i + 1)"
                transaction.dueDate = Date().addingTimeInterval(Double(i) * 86400)
                transaction.amount = Double(i) * 100.0
                transaction.isIncome = (i % 2 == 0)
            }

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Erro ao salvar contexto de preview: \(nsError), \(nsError.userInfo)")
            }
        
        return controller
    }()
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "OrganEasy")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
}
