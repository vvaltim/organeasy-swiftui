//
//  CurrencyTextField.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI

struct CurrencyTextField: View {
    @Binding var value: String
    @State private var internalValue: String = ""

    private let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "pt_BR")
        f.currencySymbol = "R$ "
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        
        return f
    }()

    var body: some View {
        HStack {
            Text("Valor")
            
            TextField("Valor", text: $internalValue)
                .multilineTextAlignment(.trailing)
                .keyboardType(.numberPad)
                .onChange(of: internalValue, initial: false) { newValue, _ in
                    let digits = newValue.filter { "0123456789".contains($0) }
                    let doubleValue = (Double(digits) ?? 0) / 100
                    if let formatted = formatter.string(from: NSNumber(value: doubleValue)) {
                        internalValue = formatted
                        value = formatted
                    } else {
                        value = newValue
                    }
                }
                .onAppear {
                    internalValue = value
                }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
            @State private var value: String = "R$ 35,32"
            var body: some View {
                CurrencyTextField(value: $value)
            }
        }
        return PreviewWrapper()
}
