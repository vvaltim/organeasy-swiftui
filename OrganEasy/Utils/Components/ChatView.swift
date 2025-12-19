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
        VStack {
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
                    .cornerRadius(16)
                    .frame(maxWidth: 250, alignment: chat.isSending ? .trailing : .leading)
                if !chat.isSending {
                    Spacer()
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct ChatLoadingView: View {

    var body: some View {
        HStack {
            Image(systemName: "ellipsis")
                .symbolEffect(.breathe)
                .padding(10)
                .background(
                    Color(UIColor.systemIndigo)
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .frame(maxWidth: 250, alignment: .leading)
            
            Spacer()
        }
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
