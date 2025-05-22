//
//  Strings+extensions.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 22/05/25.
//

extension String {
    
    // MARK: - Converte Real (R$ 0,00) para Double
    
    func concurrenceToDouble() -> Double {
        let cleaned = self
            .replacingOccurrences(of: "[^0-9,]", with: "", options: .regularExpression)
            .replacingOccurrences(of: ",", with: ".")
        return Double(cleaned) ?? 0.0
    }
}
