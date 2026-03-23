//
//  Double+extensions.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 23/05/25.
//

import Foundation

extension Double {
    func toBRL() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: NSNumber(value: self)) ?? "R$ 0,00"
    }
}
