#if DEBUG
import Foundation

enum SummarySampleReplies {
    static var isActive: Bool {
        (ShowcaseMode.isEnabled || ShowcaseMode.forcesAICard) && !SummaryAssistantAvailability.isModelReady
    }

    static func reply(to question: String) -> String? {
        guard isActive else { return nil }
        return String(localized: "Faltam quatro contas neste mês. A maior é a Luz, que vence amanhã.")
    }
}
#endif
