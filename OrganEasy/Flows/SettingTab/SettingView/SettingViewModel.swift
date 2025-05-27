//
//  SettingViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import Foundation

class SettingViewModel: ObservableObject {
    @Published var title: String = "Settings"
    @Published var isDarkMode: Bool = false
    @Published var goToBankList: Bool = false
    
    // MARK: Public Methods
    
    func onTapBankList() {
        goToBankList = true
    }
}
