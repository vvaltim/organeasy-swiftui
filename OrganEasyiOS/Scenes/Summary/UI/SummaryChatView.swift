import Combine
import FoundationModels
import SwiftUI

// MARK: - Message

struct SummaryChatMessage: Identifiable, Equatable {
    enum Role {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let text: String
}

// MARK: - Model

@MainActor
final class SummaryChatModel: ObservableObject {
    @Published private(set) var messages: [SummaryChatMessage] = []
    @Published private(set) var isResponding = false

    private let entries: [SummaryEntry]
    private let log = EntryLookupLog()
    private let context: SummaryChatContext
    private var session: LanguageModelSession

    private var failureMessage: String {
        String(localized: "Não consegui responder agora. Tente perguntar de outro jeito.")
    }

    init(entries: [SummaryEntry]) {
        self.entries = entries
        context = SummaryChatContext(entries: entries)
        session = Self.makeSession(entries: entries, log: log, facts: context.facts)
    }

    func send(_ text: String) {
        let question = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isResponding else { return }

        messages.append(SummaryChatMessage(role: .user, text: question))
        isResponding = true

        Task {
            defer { isResponding = false }
            let reply = await reply(to: question)
            messages.append(SummaryChatMessage(role: .assistant, text: reply))
        }
    }

    private func reply(to question: String) async -> String {
        #if DEBUG
        if let sample = SummarySampleReplies.reply(to: question) {
            try? await Task.sleep(for: .seconds(1))
            return sample
        }
        #endif

        await log.start(SummaryQuestionScope(question: question, entries: entries, now: .now))

        do {
            let answer = try await session.respond(to: question).content
            return await verified(answer, question: question)
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            // A conversa ficou longa: recomeça o contexto e tenta de novo.
            session = Self.makeSession(entries: entries, log: log, facts: context.facts)
            guard let answer = try? await session.respond(to: question).content else {
                return failureMessage
            }
            return await verified(answer, question: question)
        } catch {
            return failureMessage
        }
    }

    private func verified(_ answer: String, question: String) async -> String {
        context.answer(for: answer, question: question, toolReports: await log.reports)
    }

    private static func makeSession(entries: [SummaryEntry], log: EntryLookupLog, facts: String) -> LanguageModelSession {
        LanguageModelSession(
            tools: [EntryLookupTool(entries: entries, log: log)],
            instructions: SummaryAssistant.instructions(now: .now, facts: facts)
        )
    }
}

// MARK: - View

struct SummaryChatView: View {
    @StateObject private var model: SummaryChatModel
    @State private var text = ""
    @FocusState private var isFocused: Bool

    private let suggestions: [String] = [
        String(localized: "Quanto falta pagar este mês?"),
        String(localized: "Qual foi meu maior gasto este mês?"),
        String(localized: "Quanto paguei de luz este ano?")
    ]

    private enum Constants {
        static let bubbleSpacer: CGFloat = 48
        static let sendButtonSize: CGFloat = 36
    }

    init(entries: [SummaryEntry]) {
        _model = StateObject(wrappedValue: SummaryChatModel(entries: entries))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Size.x8.rawValue) {
                    ForEach(model.messages) { message in
                        bubble(message)
                            .id(message.id)
                    }

                    if model.isResponding {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("typing")
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .onChange(of: model.messages) { _, messages in
                guard let last = messages.last else { return }
                withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
            }
        }
        .safeAreaInset(edge: .bottom) {
            inputBar
        }
        .navigationTitle("Minha IA")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private func bubble(_ message: SummaryChatMessage) -> some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: Constants.bubbleSpacer)
            }

            Text(message.text)
                .padding(.horizontal, Size.x12.rawValue)
                .padding(.vertical, Size.x8.rawValue)
                .background(
                    message.role == .user ? Color.accentColor : Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: Size.x16.rawValue)
                )
                .foregroundStyle(message.role == .user ? .white : .primary)
                .accessibilityIdentifier(message.role == .assistant ? "assistantBubble" : "userBubble")

            if message.role == .assistant {
                Spacer(minLength: Constants.bubbleSpacer)
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: Size.x8.rawValue) {
            if model.messages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Size.x8.rawValue) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(suggestion) {
                                model.send(suggestion)
                            }
                            .buttonStyle(.bordered)
                            .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            HStack(spacing: Size.x8.rawValue) {
                TextField("Pergunte sobre suas contas", text: $text, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .accessibilityIdentifier("chatField")

                Button(action: submit) {
                    Image(systemName: SummaryIcon.send.rawValue)
                        .fontWeight(.semibold)
                        .frame(width: Constants.sendButtonSize, height: Constants.sendButtonSize)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isResponding)
                .accessibilityLabel("Enviar")
                .accessibilityIdentifier("chatSend")
            }
            .padding(.horizontal)
        }
        .padding(.vertical, Size.x8.rawValue)
        .background(.bar)
    }

    private func submit() {
        model.send(text)
        text = ""
    }
}

#Preview {
    NavigationStack {
        SummaryChatView(entries: [])
    }
}
