import XCTest

/// Percorre as telas em um idioma e grava todo texto visível.
final class I18nProbeUITests: XCTestCase {
    var app: XCUIApplication!
    var seen: [String] = []
    let dir = ProcessInfo.processInfo.environment["CAPTURE_DIR"] ?? NSTemporaryDirectory()
    let tag = ProcessInfo.processInfo.environment["CAPTURE_TAG"] ?? "x"

    func dump(_ screen: String) {
        sleep(1)
        var labels = Set<String>()
        for q in [app.staticTexts, app.buttons, app.textFields, app.switches, app.tabBars.buttons] {
            for e in q.allElementsBoundByIndex.prefix(70) where e.exists {
                let t = e.label.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { labels.insert(t) }
                let p = e.placeholderValue ?? ""
                if !p.isEmpty { labels.insert(p) }
            }
        }
        seen += labels.sorted().map { "\(screen)\t\($0.replacingOccurrences(of: "\n", with: " "))" }
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(tag)_\(screen).png"))
    }

    func testWalk() throws {
        continueAfterFailure = true
        let env = ProcessInfo.processInfo.environment
        let lang = env["CAPTURE_LANG"] ?? "pt-BR", locale = env["CAPTURE_LOCALE"] ?? "pt_BR"
        let f = DateFormatter(); f.dateFormat = "dd/MM/yyyy"
        let today = f.string(from: .now)
        let url = FileManager.default.temporaryDirectory.appending(path: "i18n.csv")
        try "Data;Descrição;Valor\n\(today);Salario;5.000,00\n\(today);Aluguel;-1.800,00\n\(today);Lanche;-30,00\n\(today);Lanche;-30,00\n\(today);Lanche;-30,00\n\(today);Lanche;-30,00\n".write(to: url, atomically: true, encoding: .utf8)

        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(lang))", "-AppleLocale", locale, "-resetPromotion", "-importFile", url.path(percentEncoded: false)]
        app.launch()
        sleep(4)
        dump("home0")
        let names = ["Minha IA", "My AI", "Mi IA", "Mon IA", "La mia IA"]
        let tab = app.buttons.matching(NSPredicate(format: "label IN %@", names)).firstMatch
        tab.tap()
        let confirm = app.buttons["confirmImport"]
        if confirm.waitForExistence(timeout: 12) { dump("revisao"); confirm.tap() }
        sleep(8)
        dump("ia")

        // Menu de dados
        let menu = app.buttons["dataMenu"].firstMatch
        if menu.exists { menu.tap(); dump("menu"); app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8)).tap(); sleep(1) }

        // Sugestões e fim da lista
        app.swipeUp(); sleep(1); dump("ia2")
        app.swipeUp(); sleep(1); dump("ia3")
        app.swipeDown(); app.swipeDown(); sleep(1)

        // Assinatura pelo botão do topo
        let top = app.navigationBars.buttons.element(boundBy: app.navigationBars.buttons.count - 1)
        top.tap()
        sleep(3)
        dump("assinatura")
        app.swipeDown(velocity: .fast)
        sleep(2)

        // Home com dados, formulário e recorrências
        app.tabBars.buttons.firstMatch.exists ? app.tabBars.buttons.firstMatch.tap() : app.buttons.element(boundBy: 0).tap()
        let home = app.buttons.matching(NSPredicate(format: "label IN %@", ["Home", "Inicio", "Accueil"])).firstMatch
        if home.exists { home.tap() }
        sleep(2)
        dump("home")
        app.navigationBars.buttons.element(boundBy: 0).tap(); sleep(2); dump("recorrencias")
        app.navigationBars.buttons.element(boundBy: 0).tap(); sleep(2)
        let add = app.buttons.matching(NSPredicate(format: "label IN %@", ["Adicionar lançamento", "Add entry", "Añadir movimiento", "Ajouter une opération", "Aggiungi movimento"])).firstMatch
        if add.exists { add.tap(); sleep(2); dump("form") }

        try seen.joined(separator: "\n").write(to: URL(fileURLWithPath: "\(dir)/\(tag).txt"), atomically: true, encoding: .utf8)
    }
}
