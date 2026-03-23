//
//  SettingRouter.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 23/06/25.
//

import SwiftUI
internal import Combine

enum SettingRouter: Hashable {
    case bank
    case recurringBillList
    case recurringBillForm(UUID?)
}

class SettingNavigationManager: ObservableObject {
    @Published var path = NavigationPath()
}
