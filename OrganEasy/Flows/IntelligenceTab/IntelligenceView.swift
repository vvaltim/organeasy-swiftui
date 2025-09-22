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
            VStack {
                List {
                    ForEach(viewModel.chatList, id: \.uuid) { item in
                        ChatView(chat: item)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    
                    if viewModel.isThinking {
                        HStack {
                            ProgressView()
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color(.systemBackground))
            }
        }
        .searchable(text: $viewModel.inputText, prompt: Text("Adicionar transação"))
        .onSubmit(of: .search) {
            viewModel.verifyIntention()
        }
        .navigationTitle(Text("Easynhe"))
        .onAppear {
            viewModel.setupProvider(with: provider)
            
            viewModel.initializeChat()
        }
    }
}

#Preview {
    IntelligenceView()
}
