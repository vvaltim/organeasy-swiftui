//
//  ChatView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 19/09/25.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

import SwiftUI

struct ChatView: View {
    
    let chat: ChatMessage

    var backgroundColor: Color {
        #if os(iOS)
        return !chat.isSending ? Color(UIColor.systemIndigo) : Color(UIColor.systemGray)
        #elseif os(macOS)
        return !chat.isSending ? Color(nsColor: NSColor.systemIndigo) : Color(nsColor: NSColor.systemGray)
        #endif
    }

    var body: some View {
        VStack {
            HStack {
                if chat.isSending {
                    Spacer()
                }
                Text(chat.text)
                    .padding(10)
                    .background(
                        backgroundColor
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
    
    var backgroundColor: Color {
        #if os(iOS)
        return Color(UIColor.systemIndigo)
        #elseif os(macOS)
        return Color(nsColor: NSColor.systemIndigo)
        #endif
    }

    var body: some View {
        HStack {
            Image(systemName: "ellipsis")
                .symbolEffect(.breathe)
                .padding(10)
                .background(
                    backgroundColor
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
