//
//  ChatView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 19/09/25.
//

import SwiftUI

struct ChatView: View {
    
    let chat: ChatMessage

    var body: some View {
        HStack {
            if chat.isSending {
                Spacer()
            }
            Text(chat.text)
                .padding(10)
                .background(
                    !chat.isSending ? Color(UIColor.systemIndigo) : Color(UIColor.systemGray)
                )
                .foregroundColor(.white)
                .cornerRadius(16, corners: !chat.isSending ? [.topLeft, .topRight, .bottomRight] : [.topLeft, .topRight, .bottomLeft])
                .frame(maxWidth: 250, alignment: chat.isSending ? .trailing : .leading)
            if !chat.isSending {
                Spacer()
            }
        }
        .padding(chat.isSending ? .trailing : .leading, 16)
    }
}

fileprivate struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

fileprivate extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

#Preview {
    ChatView(
        chat: ChatMessage(
            text: "Desculpe, não entendi",
            isSending: true
        )
    )
}
