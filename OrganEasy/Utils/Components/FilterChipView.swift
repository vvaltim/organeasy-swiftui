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
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.secondarySystemGroupedBackground))
                .foregroundColor(isSelected ? Color.accentColor : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .shadow(color: isSelected ? Color.accentColor.opacity(0.15) : .clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
