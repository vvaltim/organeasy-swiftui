//
//  SettingViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import CloudKit
import CoreData
import Foundation

class SettingViewModel: ObservableObject {
    @Published var title: String = "Settings"
    @Published var isDarkMode: Bool = false
    @Published var goToBankList: Bool = false
    @Published var version: String = "1.0.0"
    @Published var iCloudStatus: String = "Desconhecido"
    
    // MARK: Constructor
    
    init() {
        verifyUserCloudKit()
        verifyAppVersion()
    }
    
    // MARK: Public Methods
    
    func onTapBankList() {
        goToBankList = true
    }
    
    func clearAllData() {
        let context = PersistenceController.shared.container.viewContext
        let entityNames = context.persistentStoreCoordinator?.managedObjectModel.entities.map { $0.name! } ?? []
        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try context.execute(batchDeleteRequest)
            } catch {
                print("Erro ao apagar dados da entidade \(entityName): \(error)")
            }
        }
        do {
            try context.save()
        } catch {
            print("Erro ao salvar contexto após apagar dados: \(error)")
        }
    }
    
    // MARK: Private Functions
    
    private func verifyUserCloudKit() {
        // CloudKit não funciona na conta gratuita da apple
        /*CKContainer.default().accountStatus { [weak self] status, error in
            guard let self = self else { return }
            
            switch status {
            case .available:
                self.iCloudStatus = "Disponível"
            case .noAccount:
                self.iCloudStatus = "Não está logado"
            case .restricted, .couldNotDetermine:
                self.iCloudStatus = "Indisponível"
            case .temporarilyUnavailable:
                self.iCloudStatus = "Indisponível no momento"
            @unknown default:
                self.iCloudStatus = "Desconhecido"
                break
            }
        }*/
    }
    
    private func verifyAppVersion() {
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        let build = Bundle.main.infoDictionary?["CFBundleVersion"]
        
        version = "\(shortVersion ?? "Desconhecido") (\(build ?? "Desconhecido"))"
    }
}
