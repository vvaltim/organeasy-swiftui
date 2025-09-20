//
//  IntelligenceViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 18/09/25.
//

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
    
    private var lastMessage = ""
    private var service = IntelligenceService()
    
    // MARK: - Methods
    
    func initializeChat() {
        chatList = []
        
        service.initializeChat(
            prompt: "Se apresente para o usuário de forma bem sucinta, e conta o que vc faz"
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
                self.addToChat(
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
        
        service.checkIntentions(
            prompt: "Texto: \(lastMessage) Qual a intenção do usuário?"
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let intention):
                processIntention(with: intention)
            case .failure(let error):
                self.addToChat(
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
            addToChat(
                with: ChatMessage(
                    text: "Eu ainda n sei fazer isso",
                    isSending: false
                )
            )
        }
    }
    
    func extractTransaction() {
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            
            if !model.isAvailable {
                return
            }
            
            let instructions = """
            Você é um assistente que extrai informações estruturadas de despesas a partir de um texto em português.
            - amount (Double)
            - descriptionText (String)
            - dueDate (Date, formato ISO 8601)
            - isIncome (Bool)
            Se algum campo não estiver presente, use null ou false.
            """
            let session = LanguageModelSession(instructions: instructions)
            
            let prompt = """
            Texto: "\(lastMessage)"
            Extraia os campos conforme as instruções.
            """
            
            Task {
                do {
                    let options = GenerationOptions(temperature: 0.2)
                    let response = try await session.respond(to: prompt, generating: TransactionGenerable.self, options: options)
                    
                    addToChat(with: ChatMessage(text: "Certo, vou adicionar essa despesa!", isSending: false))
                    addToChat(with: ChatMessage(text: response.content.getTransaction(), isSending: false))
                } catch {
                    addToChat(with: ChatMessage(text: "Erro ao gerar resposta: \(error)", isSending: false))
                }
            }
        } else {
            print("Não suportado na versão da API da Apple")
        }
        
    }
    
    private func addToChat(with message: ChatMessage) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.chatList.append(message)
        }
    }
}

