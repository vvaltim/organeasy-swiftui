//
//  HomeView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import FoundationModels
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var provider: RepositoryProvider
    @StateObject var viewModel: HomeViewModel = HomeViewModel()
    @StateObject private var navManager = HomeNavigationManager()
    @State private var selectedMonth: Date? = Date()
    @State var showAlertDuplicate = false
    @State private var session: LanguageModelSession?
    @State private var alert = ""
    let instruction = Instructions {
        "Você é uma assistente financeira que ajuda as pessoas a manter a vida financeira organizada."
        "Responda de forma clara e sucinta para facilitar a organização financeira."
        "Usa a ferramente 'transactionTool' para encontrar as transações que ainda não foram pagas"
    }
    
    var body: some View {
        NavigationStack(path: $navManager.path) {
            Group {
                if viewModel.transactions.isEmpty {
                    EmptyStateView(
                        imageName: "tray",
                        title: "label_empty_data",
                        message: "",
                        actionTitle: nil,
                        action: { }
                    )
                } else {
                    VStack {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.months, id: \.self) { month in
                                    FilterChipView(
                                        label: month.formatToMonthYear(),
                                        isSelected: selectedMonth == month,
                                        action: {
                                            selectedMonth = month
                                            viewModel.filterPerMonth(with: month)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        
                        List {
                            if session?.isResponding == true {
                                Section {
                                    ProgressView()
                                }
                            }
                            
                            if !alert.isEmpty {
                                Section {
                                    Text(alert)
                                }
                            }
                            
                            Section(
                                header: FinanceSummaryCard(
                                    input: viewModel.input,
                                    output: viewModel.output
                                )
                                .padding(.vertical, 20)
                                .listRowInsets(EdgeInsets())
                            ) {
                                ForEach(viewModel.transactions, id: \.objectID) { transaction in
                                    MonthTransactionDetailItemView(
                                        descriptionText: transaction.descriptionText,
                                        dueDate: transaction.dueDate.formatTo(dateFormat: "dd/MM"),
                                        paymentDate: transaction.paymentDate?.formatTo(dateFormat: "dd/MM"),
                                        ammount: transaction.amount.toBRL(),
                                        isIncome: transaction.isIncome,
                                        isSlash: transaction.isSlash,
                                        canPay: transaction.canPay(),
                                        canSlash: transaction.canSlash()
                                    ) { type in
                                        switch type {
                                        case .tap:
                                            navManager.path.append(HomeRouter.transaction(transaction.id))
                                        case .paid:
                                            viewModel.markToPaid(transaction: transaction)
                                        case .slash:
                                            viewModel.changeSlash(transaction: transaction)
                                        case .delete:
                                            viewModel.delete(transaction: transaction)
                                        }
                                    }
                                    .listRowBackground(rowBackground(for: transaction))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text("tab_home"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.showDuplicateButton {
                    ToolbarItem {
                        Button(
                            action: {
                                showAlertDuplicate = true
                            }
                        ) {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                    
                    ToolbarSpacer(.fixed)
                }
                
                ToolbarItem {
                    Button(
                        action: {
                            navManager.path.append(HomeRouter.transaction(nil))
                        }
                    ) {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: HomeRouter.self) { router in
                switch router {
                case .month(let month):
                    MonthTransactionDetailView(
                        month: month
                    )
                case .transaction(let id):
                    TransactionView(
                        onClose: {
                            navManager.path.removeLast()
                            
                            viewModel.fetchTransactions()
                        },
                        transactionID: id
                    )
                }
            }
            .alert(isPresented: $showAlertDuplicate) {
                Alert(
                    title: Text("Deseja mesmo duplicar os itens do mês selecionado, e inserir no mês atual?"),
                    primaryButton: .destructive(Text("button_yes")) {
                        viewModel.duplicateMonth()
                    },
                    secondaryButton: .cancel(Text("button_no")) {
                        showAlertDuplicate = false
                    }
                )
            }
            .onAppear {
                viewModel.setupProvider(with: provider)
                
                viewModel.fetchTransactions()
                viewModel.requestNotificationPermission()
                
                selectedMonth = viewModel.months.first
                
                Task {
                    
                    session = LanguageModelSession(
                        tools: [
                            TransactionTool(
                                transactions: provider.transactionRepository.fetchAllDTO()
                            )
                        ],
                        instructions: instruction
                    )
                    
                    try await verifyTransactions()
                }
            }
        }
        .environmentObject(navManager)
    }
    
    private func rowBackground(for transaction: Transaction) -> some View {
        if transaction.addWithIA {
            return AnyView(
                AppleIntelligenceGradientBackground()
            )
        } else {
            return AnyView(Color(UIColor.secondarySystemGroupedBackground))
        }
    }
    
    private func verifyTransactions() async throws {
        guard let session = session else { return }
        let response = try await session.respond(to: "Quais as transações que ainda não foram pagas?")
        alert = response.content.description
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let provider = RepositoryProvider(context: context)
    
    HomeView()
        .environmentObject(provider)
}
