//
//  IntelligenceViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 18/09/25.
//

import FirebaseAnalytics
import Foundation
import FoundationModels

struct ChatMessage: Hashable {
    let uuid: UUID = UUID()
    var text: String
    var isSending: Bool
}

class IntelligenceViewModel: ObservableObject {
    
    // MARK: - Variables
    
    @Published public var inputText: String = ""
    @Published public var chatList: [ChatMessage] = []
    @Published public var isThinking: Bool = false
    @Published public var showHelp: Bool = false
    
    private var repositoryTransaction: TransactionRepositoryProtocol?
    
    private var lastMessage = ""
    private var service = IntelligenceService()
    
    // MARK: - Public Methods
    
    func setupProvider(with provider: RepositoryProvider) {
        repositoryTransaction = provider.transactionRepository
    }
    
    func initializeChat() {
        isThinking = true
        
        service.initializeChat(
            prompt: "Pergunta como vc pode ajudar hoje"
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                self.addToChat(
                    with: ChatMessage(
                        text: response,
                        isSending: false
                    )
                )
            case .failure(let error):
                self.showError(
                    with: ChatMessage(
                        text: error.localizedDescription,
                        isSending: false
                    )
                )
            }
        }
    }
    
    func verifyIntention() {
        lastMessage = inputText
        inputText = ""
        
        addToChat(
            with: ChatMessage(
                text: lastMessage,
                isSending: true
            )
        )
        isThinking = true
        
        service.checkIntentions(
            prompt: "Texto: \(lastMessage) Qual a intenção do usuário?"
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let intention):
                processIntention(with: intention)
            case .failure(let error):
                self.showError(
                    with: ChatMessage(
                        text: error.localizedDescription,
                        isSending: false
                    )
                )
            }
        }
    }
    
    func showHelpView() {
        showHelp = true
    }
    
    // MARK: - Private Methods
    
    private func extractTransaction() {
        service.processTransaction(
            prompt: "Texto: \(lastMessage) Extraia os campos conforme as instruções."
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let dto):
                repositoryTransaction?.add(with: dto)
                
                addToChat(
                    with: ChatMessage(
                        text: "Certo, eu adicionei a transação \(dto.descriptionText) com vencimento em \(dto.dueDate.formatToMonthYear())!",
                        isSending: false
                    )
                )
            case .failure(let error):
                self.showError(
                    with: ChatMessage(
                        text: error.localizedDescription,
                        isSending: false
                    )
                )
            }
        }
    }
    
    private func processIntention(with intention: String) {
        switch intention {
        case "cadastrar_transacao":
            extractTransaction()
        default:
            showError(
                with: ChatMessage(
                    text: "Eu ainda n sei fazer isso",
                    isSending: false
                )
            )
        }
    }
    
    private func addToChat(with message: ChatMessage) {
        chatList.append(message)
        isThinking = false
    }
    
    private func showError(with message: ChatMessage) {
        Analytics.logEvent(
            "pergunta_sem_resposta",
            parameters: [
                "pergunta": lastMessage,
                "resposta": message.text
            ]
        )
        
        addToChat(with: message)
    }
}

