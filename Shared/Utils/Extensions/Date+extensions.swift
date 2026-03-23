//
//  Date+extensions.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 23/05/25.
//

import Foundation

extension Date {
    
    // Converte um Date para "MMMM 'de' yyyy"
    
    func formatToMonthYear() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM 'de' yyyy"
        dateFormatter.locale = Locale(identifier: "pt_BR")
        return dateFormatter.string(from: self).captainizeFirstLetter()
    }
    
    func formatTo(dateFormat: String = "dd/MM/yyyy") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale(identifier: "pt_BR")
        return dateFormatter.string(from: self)
    }
}
