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
            ZStack {
                VStack {
                    ScrollViewReader { proxy in
                        List {
                            ForEach(viewModel.chatList, id: \.uuid) { item in
                                ChatView(chat: item)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .id(item.uuid)
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .background(Color(.systemBackground))
                        .onChange(of: viewModel.chatList.count) {
                            if let last = viewModel.chatList.last {
                                withAnimation {
                                    proxy.scrollTo(last.uuid, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                if viewModel.isThinking {
                    VStack {
                        Spacer()
                        HStack {
                            ChatLoadingView()
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: viewModel.isThinking)
                }
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
