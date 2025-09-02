//
//  FeatureToggle.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 07/08/25.
//

import FirebaseCore

public enum FeatureToggle: String, CaseIterable {
    case isEnableRecurrence = "recurrency_menu"
}

import FirebaseRemoteConfig

class RemoteConfigManager: ObservableObject {
    
    @Published private(set) var featureFlags: [FeatureToggle: Bool] = [:]
    
    private var remoteConfig: RemoteConfig
    
    init() {
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        
        var defaults: [String: NSObject] = [:]
        for flag in FeatureToggle.allCases {
            defaults[flag.rawValue] = false as NSObject
        }
        remoteConfig.setDefaults(defaults)
        
        fetchRemoteConfig()
    }
    
    func fetchRemoteConfig() {
        remoteConfig.fetchAndActivate { [weak self] status, error in
            if let error = error {
                print("Erro ao buscar Remote Config: \(error)")
                return
            }
            
            guard let self = self else { return }
            var updatedFlags: [FeatureToggle: Bool] = [:]
            for flag in FeatureToggle.allCases {
                let value = self.remoteConfig.configValue(forKey: flag.rawValue).boolValue
                updatedFlags[flag] = value
            }
            
            DispatchQueue.main.async {
                self.featureFlags = updatedFlags
            }
        }
    }
    
    func isFeatureEnabled(_ flag: FeatureToggle) -> Bool {
        featureFlags[flag] ?? false
    }
}
