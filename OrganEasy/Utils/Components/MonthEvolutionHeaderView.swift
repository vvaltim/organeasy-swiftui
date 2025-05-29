//
//  MonthEvolutionHeaderView.swift
//  OrganEasy
//
//  Created by Walter Vanio dos Reis Junior on 29/05/25.
//

import SwiftUI

struct MonthEvolutionHeaderView: View {
    let label: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value.toBRL())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .stroke(
                    Color.gray.opacity(0.3),
                    lineWidth: 1
                )
        )
        .padding(.vertical)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    MonthEvolutionHeaderView(
        label: "Total",
        value: 34.42
    )
}
