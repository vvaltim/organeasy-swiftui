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
                                    .listRowInsets(EdgeInsets())
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
                        .padding(.leading, 3)
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: viewModel.isThinking)
                }
            }
            .navigationTitle("Easynhe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Text("Easynhe")
                        Text("BETA")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.orange)
                            .padding(.horizontal, 4)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
                
                ToolbarItem {
                    Button(action: {
                        viewModel.showHelpView()
                    }) {
                        Image(systemName: "questionmark")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showHelp) {
                NavigationStack {
                    HelpView()
                }
            }
        }
        .searchable(text: $viewModel.inputText, prompt: Text("Adicionar transação"))
        .onSubmit(of: .search) {
            viewModel.verifyIntention()
        }
        .onAppear {
            viewModel.setupProvider(with: provider)
            
            viewModel.initializeChat()
        }
    }
}

#Preview {
    IntelligenceView()
}
