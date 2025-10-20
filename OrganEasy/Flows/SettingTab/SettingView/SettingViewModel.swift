//
//  SettingViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import CloudKit
import CoreData
import Foundation
import FoundationModels

class SettingViewModel: ObservableObject {
    @Published var title: String = "Settings"
    @Published var isDarkMode: Bool = false
    @Published var goToBankList: Bool = false
    @Published var version: String = "1.0.0"
    @Published var iCloudStatus: String = "Desconhecido"
    @Published var appleIntelligenceStatus: String = "Desconhecido"
    
    // MARK: Constructor
    
    init() {
        verifyUserCloudKit()
        verifyAppleIntelligence()
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
        CKContainer.default().accountStatus { [weak self] status, error in
            guard let self = self else { return }
            
            switch status {
            case .available:
                self.iCloudStatus = "Sincronização ativada"
            case .noAccount:
                self.iCloudStatus = "Sincronização desativada. Faça login nos Ajustes para ativar a sincronização."
            case .restricted:
                self.iCloudStatus = "Sincronização restrita neste dispositivo. Verifique as configurações de restrição ou entre em contato com o administrador."
            case .couldNotDetermine:
                self.iCloudStatus = "Não foi possível verificar o status. Tente novamente mais tarde."
            case .temporarilyUnavailable:
                self.iCloudStatus = "Temporariamente indisponível. Tente novamente em alguns minutos."
            default:
                self.iCloudStatus = "Erro desconhecido ao verificar o iCloud."
                break
            }
        }
    }
    
    private func verifyAppleIntelligence() {
        switch SystemLanguageModel.default.availability {
        case .available:
            self.appleIntelligenceStatus = "Disponível e pronta para uso"
        case .unavailable(.appleIntelligenceNotEnabled):
            self.appleIntelligenceStatus = "Desativada. Para ativar, acesse Ajustes > Apple Intelligence e Siri > Apple Intelligence."
        case .unavailable(.deviceNotEligible):
            self.appleIntelligenceStatus = "Incompatível com este dispositivo. Requer um iPhone 15 Pro ou modelo mais recente."
        case .unavailable(.modelNotReady):
            self.appleIntelligenceStatus = "Temporariamente indisponível. Pode estar sendo baixada ou passando por manutenção. Tente novamente em alguns minutos."
        case .unavailable(_):
            self.appleIntelligenceStatus = "Temporariamente indisponível."
        }
    }
    
    private func verifyAppVersion() {
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        let build = Bundle.main.infoDictionary?["CFBundleVersion"]
        
        version = "\(shortVersion ?? "Desconhecido") (\(build ?? "Desconhecido"))"
    }
}
