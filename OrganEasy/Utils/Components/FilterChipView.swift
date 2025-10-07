//
//  FilterChipView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 08/09/25.
//

import SwiftUI

struct FilterChipView: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color(UIColor.secondarySystemBackground))
                .foregroundColor(isSelected ? Color.accentColor : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FilterChipView(
        label: "Testando",
        isSelected: false,
        action: {}
    )
}
