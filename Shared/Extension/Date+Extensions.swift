//
//  Date+Extensions.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/06/26.
//

import Foundation

extension Date {
    func getCurrentReference(with reference: Int) -> String {
        var comps = Calendar.current.dateComponents([.year, .month], from: self)
        if let month = comps.month { comps.month = month + reference }
        let date = Calendar.current.date(from: comps) ?? self
        return date.formatted(.dateTime.year(.twoDigits).month(.twoDigits))
    }
    
    func getDateFormatted(with format: DateFormatConstant) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt-BR") //Locale.current Depois ver como pegar automatico com a internalizacionation
        formatter.dateFormat = format.rawValue

        return formatter.string(from: self).capitalized
    }
    
    func getReferenceMonth() -> String {
        return self.formatted(.dateTime.year(.twoDigits).month(.twoDigits))
    }
}
