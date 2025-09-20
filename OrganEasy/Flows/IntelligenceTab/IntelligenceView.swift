//
//  IntelligenceView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 18/09/25.
//

import SwiftUI

struct IntelligenceView: View {
    
    @EnvironmentObject var provider: RepositoryProvider
    @StateObject var viewModel: IntelligenceViewModel = IntelligenceViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.chatList, id: \.uuid) { item in
                    ChatView(chat: item)
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .navigationTitle("Assistente")
            .searchable(text: $viewModel.inputText, prompt: Text("Adicione uma despesa de ..."))
            .onSubmit(of: .search) {
                viewModel.verifyIntention()
            }
        }
        .onAppear {
            viewModel.initializeChat()
        }
    }
}

#Preview {
    IntelligenceView()
}
