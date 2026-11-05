import XCTest

/// IA real em cada idioma, com os dados da vitrine e sem anúncios.
final class AIProbeUITests: XCTestCase {
    func testChat() throws {
        continueAfterFailure = true
        let env = ProcessInfo.processInfo.environment
        let lang = env["CAPTURE_LANG"] ?? "pt-BR", locale = env["CAPTURE_LOCALE"] ?? "pt_BR"
        let qs: [String: [String]] = [
            "pt": ["qual meus gasto", "Quanto falta pagar este mês?", "Como posso economizar?", "Quanto gastei com academia?"],
            "en": ["what are my expenses", "How much is left to pay this month?", "How can I save money?", "How much did I spend on gym?"],
            "es": ["cuáles son mis gastos", "¿Cuánto falta por pagar este mes?", "¿Cómo puedo ahorrar?", "¿Cuánto gasté en gimnasio?"],
            "fr": ["quelles sont mes dépenses", "Combien reste-t-il à payer ce mois-ci ?", "Comment économiser ?", "Combien ai-je dépensé pour la gym ?"],
            "it": ["quali sono le mie spese", "Quanto resta da pagare questo mese?", "Come posso risparmiare?", "Quanto ho speso per la palestra?"]
        ]
        let app = XCUIApplication()
        app.launchArguments = ["-showcase", "-AppleLanguages", "(\(lang))", "-AppleLocale", locale]
        app.launch()
        sleep(3)
        app.buttons.matching(NSPredicate(format: "label IN %@", ["Minha IA", "My AI", "Mi IA", "Mon IA", "La mia IA"])).firstMatch.tap()
        sleep(3)
        let chat = app.buttons["openChat"]
        XCTAssertTrue(chat.waitForExistence(timeout: 8))
        chat.tap(); sleep(2)
        let field = app.textFields["chatField"].exists ? app.textFields["chatField"] : app.textViews["chatField"]
        let bubbles = app.descendants(matching: .any).matching(identifier: "assistantBubble")
        for q in qs[String(lang.prefix(2))] ?? [] {
            let before = bubbles.count
            field.tap(); field.typeText(q)
            app.buttons["chatSend"].tap()
            var w = 0
            while bubbles.count == before && w < 40 { sleep(1); w += 1 }
            sleep(1)
            let a = bubbles.count > before ? bubbles.element(boundBy: bubbles.count - 1).label : "SEM RESPOSTA"
            print("AI[\(lang)] \(q) => \(a.replacingOccurrences(of: "\n", with: " / "))")
        }
    }
}
