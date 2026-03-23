//
//  EmptyStateView.swift
//  OrganEasy
//
//  Created by Walter Vanio dos Reis Junior on 30/05/25.
//

import SwiftUI

struct EmptyStateView: View {
    
    let imageName: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(.gray.opacity(0.5))
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            Text(message)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        imageName: "tray",
        title: "Teste",
        message: "Testando",
        actionTitle: "Action?",
        action: nil
    )
}
