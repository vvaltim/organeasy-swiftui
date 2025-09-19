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
    
    // MARK: - Methods
    
    func initializeChat() {
        chatList = []
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            
            if !model.isAvailable {
                return
            }
            
            let instructions = "Você é um assistente pessoal de genero neutro chamada Easynha, que ajuda pessoas a organizar suas finanças. Você tem um tom de voz bem descontraido, e é bem intima do usuário. Alem disso vc pode ajudar ele a organizar suas finanças, e atualmente vc apenas inserir informações de transação no app"
            let session = LanguageModelSession(instructions: instructions)
            
            let prompt = "Se apresente para o usuário de forma bem sucinta, e conta o que vc faz"
            
            Task {
                do {
                    let response = try await session.respond(to: prompt)
                    print(response)
                    
                    DispatchQueue.main.async {
                        self.chatList.append(ChatMessage(text: response.content, isSending: false))
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.chatList.append(ChatMessage(text: "Eu não to bem não em: \(error)", isSending: false))
                    }
                }
            }
        } else {
            print("Não suportado na versão da API da Apple")
        }
    }
    
    func processText() {
        chatList.append(ChatMessage(text: inputText, isSending: true))
        inputText = ""
        
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
            Texto: "\(inputText)"
            Extraia os campos conforme as instruções.
            """
            
            Task {
                do {
                    let options = GenerationOptions(temperature: 0.2)
                    let response = try await session.respond(to: prompt, generating: TransactionGenerable.self, options: options)
                    print(response)
                    
                    DispatchQueue.main.async {
                        self.chatList.append(ChatMessage(text: "Certo, vou adicionar essa despesa!", isSending: false))
                        self.chatList.append(ChatMessage(text: response.content.getTransaction(), isSending: false))
                    }
                } catch {
                    print("Erro ao gerar resposta: \(error)")
                    DispatchQueue.main.async {
                        self.chatList.append(ChatMessage(text: "Erro ao gerar resposta: \(error)", isSending: false))
                    }
                }
            }
        } else {
            print("Não suportado na versão da API da Apple")
        }
        
    }
}

