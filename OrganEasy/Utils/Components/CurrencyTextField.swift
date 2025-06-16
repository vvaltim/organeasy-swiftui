//
//  CurrencyTextField.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI

struct CurrencyTextField: View {
    @Binding var value: Double
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    
    private let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "R$ "
        f.locale = Locale(identifier: "pt_BR")
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }()
    
    var body: some View {
        HStack {
            Text("R$")
                .foregroundColor(.gray)
            TextField("0,00", text: Binding(
                get: {
                    self.text
                },
                set: { newValue in
                    let digits = newValue
                        .components(separatedBy: CharacterSet.decimalDigits.inverted)
                        .joined()
                    let doubleValue = (Double(digits) ?? 0) / 100
                    self.value = doubleValue
                    if let formatted = formatter.string(from: NSNumber(value: doubleValue)) {
                        self.text = formatted.replacingOccurrences(of: "R$ ", with: "")
                    } else {
                        self.text = ""
                    }
                }
            ))
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .focused($isFocused)
        }
        .onChange(of: isFocused, initial: false) { focused, _ in
            if !focused {
                text = ""
                value = 0
            }
        }
        .onAppear {
            if let formatted = formatter.string(from: NSNumber(value: value)) {
                self.text = formatted.replacingOccurrences(of: "R$ ", with: "")
            }
        }
    }
}


#Preview {
    struct PreviewWrapper: View {
        @State private var value: Double = 35.32
        var body: some View {
            CurrencyTextField(value: $value)
        }
    }
    return PreviewWrapper()
}
