//
//  MonthEvolutionHeaderView.swift
//  OrganEasy
//
//  Created by Walter Vanio dos Reis Junior on 29/05/25.
//

import SwiftUI

struct MonthEvolutionHeaderView: View {
    let label: LocalizedStringKey
    let value: Double
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
            Text(value.toBRL())
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding()
//        .glassEffect(in: .rect(cornerRadius: 24.00))
        .modifier(GlassEffectIfAvailable())
        .padding(.vertical)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    MonthEvolutionHeaderView(
        label: "Total",
        value: 34.42
    )
}
