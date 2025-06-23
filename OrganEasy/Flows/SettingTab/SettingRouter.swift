//
//  SettingRouter.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 23/06/25.
//

import SwiftUI

enum SettingRouter: Hashable {
    case bank
    case recurringBillList
    case recurringBillForm(UUID?)
}

class SettingNavigationManager: ObservableObject {
    @Published var path = NavigationPath()
}
