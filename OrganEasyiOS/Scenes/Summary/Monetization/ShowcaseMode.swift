import Foundation

/// Modo vitrine: usado só em debug para capturas e vídeos da loja, com a experiência sem anúncios.
enum ShowcaseMode {
    static var isEnabled: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-showcase")
        #else
        false
        #endif
    }

    /// Mostra o cartão da IA no simulador, que não tem o modelo.
    static var forcesAICard: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-forceAICard")
        #else
        false
        #endif
    }

    /// Abre um extrato direto na revisão, porque o seletor de arquivos não é automatizável.
    static var importFilePath: String? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "importFile")
        #else
        nil
        #endif
    }

    /// Reinicia o prazo da promoção nos testes automatizados.
    static var resetsPromotion: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-resetPromotion")
        #else
        false
        #endif
    }
}
