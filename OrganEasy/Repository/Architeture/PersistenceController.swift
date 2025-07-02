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
        
        // Add 5 transactions
        for i in 0..<5 {
            let transaction = Transaction(context: viewContext)
            transaction.id = UUID()
            transaction.descriptionText = "Transação \(i + 1)"
            transaction.dueDate = Date().addingTimeInterval(Double(i) * 86400)
            transaction.amount = Double(i) * 100.0
            transaction.isIncome = (i % 2 == 0)
            transaction.isSlash = (i % 2 != 0)
        }
        
        // Add 2 banks
        var banks: [Bank] = []
        for i in 0..<2 {
            let bank = Bank(context: viewContext)
            bank.id = UUID()
            bank.name = "Banco \(i + 1)"
            bank.isHidden = (i == 1)
            banks.append(bank)
        }
        
        // Add 5 evolutions, alternando entre os bancos criados
        for i in 0..<5 {
            let evolution = Evolution(context: viewContext)
            evolution.id = UUID()
            evolution.value = Double(i) * 50.0
            evolution.date = Date().addingTimeInterval(Double(i) * 43200)
            evolution.bank = banks[i % banks.count]
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
        
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description?.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.vanio.walter.app")
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
}
