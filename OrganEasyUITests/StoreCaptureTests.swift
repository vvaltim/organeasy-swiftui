import XCTest

/// Percorre o app de verdade no simulador. Gera as capturas da loja e o roteiro do vídeo.
final class StoreCaptureTests: XCTestCase {
    private var app: XCUIApplication!

    private var captureDir: String {
        ProcessInfo.processInfo.environment["CAPTURE_DIR"] ?? NSTemporaryDirectory()
    }

    private var prefix: String {
        ProcessInfo.processInfo.environment["CAPTURE_PREFIX"] ?? "shot"
    }

    private func launch(_ arguments: [String]) {
        app = XCUIApplication()
        var args = arguments
        if let language = ProcessInfo.processInfo.environment["CAPTURE_LANG"],
           let locale = ProcessInfo.processInfo.environment["CAPTURE_LOCALE"] {
            args += ["-AppleLanguages", "(\(language))", "-AppleLocale", locale]
        }
        app.launchArguments = args
        app.launch()
    }

    private func capture(_ name: String) {
        let path = "\(captureDir)/\(prefix)_\(name).png"
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: path))
    }

    private func pause(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }

    private var aiTab: XCUIElement {
        let names = ["Minha IA", "My AI", "Mi IA", "Mon IA", "La mia IA"]
        return app.buttons.matching(NSPredicate(format: "label IN %@", names)).firstMatch
    }

    func testStoreScreens() {
        launch(["-showcase"])
        pause(2)
        capture("1_home")

        aiTab.tap()
        pause(2)
        capture("2_ia")

        let analyze = app.buttons["analyzeMonth"]
        XCTAssertTrue(analyze.waitForExistence(timeout: 5))
        analyze.tap()
        XCTAssertTrue(element("insights").waitForExistence(timeout: 90), "análise sem resposta")
        pause(1)
        capture("3_analise")

        app.swipeUp()
        pause(1)
        app.swipeUp()
        pause(1.5)
        capture("4_grafico")

        app.swipeDown()
        pause(0.5)
        app.swipeDown()
        pause(1)
        app.buttons["openChat"].tap()
        pause(1.5)
        app.buttons.element(matching: NSPredicate(format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@ OR label CONTAINS[c] %@", "falta", "left", "?")).firstMatch.tap()
        XCTAssertTrue(element("assistantBubble").waitForExistence(timeout: 90), "chat sem resposta")
        pause(1)
        capture("5_chat")
    }

    func testPromoVideoScript() {
        launch(["-showcase"])
        pause(3)
        app.swipeUp()
        pause(1)
        app.swipeDown()
        pause(1.5)
        aiTab.tap()
        pause(3.5)
        app.buttons["analyzeMonth"].tap()
        XCTAssertTrue(element("insights").waitForExistence(timeout: 90))
        pause(3)
        app.swipeUp()
        pause(2.5)
        app.swipeUp()
        pause(2.5)
        app.swipeDown()
        pause(0.8)
        app.swipeDown()
        pause(1.2)
        app.buttons["openChat"].tap()
        pause(1.8)
        app.buttons.element(matching: NSPredicate(format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@ OR label CONTAINS[c] %@", "falta", "left", "?")).firstMatch.tap()
        XCTAssertTrue(element("assistantBubble").waitForExistence(timeout: 90))
        pause(9)
    }

    /// Fluxo do usuário grátis com anúncios de teste do Google.
    func testFreeUserFlowWithTestAds() {
        launch(["-forceAICard", "-resetPromotion"])
        pause(2)
        capture("ads_0_home_sem_anuncio")
        aiTab.tap()
        pause(9)
        capture("ads_1_promo_banner")

        XCTAssertTrue(app.buttons["promotionBanner"].waitForExistence(timeout: 5))
        app.buttons["promotionBanner"].tap()
        pause(2)
        capture("ads_2_oferta")
        app.navigationBars.buttons.firstMatch.tap()
        pause(1.5)

        // O botão é o mesmo de quem não vê anúncios: o vídeo vem antes de navegar.
        let chat = app.buttons["openChat"]
        XCTAssertTrue(chat.waitForExistence(timeout: 5))
        chat.tap()
        pause(8)
        capture("ads_3_video")
        pause(32)
        capture("ads_4_video_fim")
        closeRewardedAd()
        pause(2)
        capture("ads_5_chat_apos_video")
    }

    /// Importa um extrato de exemplo e abre as sugestões de economia.
    func testStatementImportAndSavings() throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let today = formatter.string(from: .now)
        let lastMonth = formatter.string(from: Calendar.current.date(byAdding: .month, value: -1, to: .now)!)
        let csv = """
        Conta ;12345
        Saldo ;1.000,00

        Data;Descrição;Valor;Saldo
        \(today);Mercado;-890,50;100,00
        \(today);Lanche;-30,00;70,00
        \(today);Lanche;-30,00;40,00
        \(today);Lanche;-30,00;10,00
        \(today);Lanche;-30,00;0,00
        \(today);Salário;5.000,00;5.000,00
        \(lastMonth);Mercado;-500,00;500,00
        """
        let url = FileManager.default.temporaryDirectory.appending(path: "extrato.csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)

        launch(["-forceAICard", "-importFile", url.path(percentEncoded: false)])
        aiTab.tap()

        let confirm = app.buttons["confirmImport"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 15))
        pause(1)
        capture("import_1_revisao")
        confirm.tap()
        pause(3)
        capture("import_2_minha_ia")

        let savings = app.buttons["savingsButton"]
        for _ in 0..<4 where !savings.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(savings.waitForExistence(timeout: 5))
        capture("import_3_botao")
        savings.tap()
        pause(40)
        closeRewardedAd()
        pause(2)
        capture("import_4_sugestoes")
    }

    /// O botão da Home precisa abrir o compartilhamento com o arquivo.
    func testExportOpensShareSheet() {
        launch(["-showcase"])
        pause(2)
        let export = app.buttons["Exportar dados"].firstMatch
        if !export.waitForExistence(timeout: 3) {
            app.navigationBars.buttons.element(boundBy: app.navigationBars.buttons.count - 1).tap()
            pause(1)
        }
        XCTAssertTrue(export.waitForExistence(timeout: 5))
        export.tap()
        pause(3)
        capture("export_share")
        XCTAssertTrue(app.otherElements["ActivityListView"].exists || app.collectionViews.count > 0)
    }

    private func closeRewardedAd() {
        for name in ["Close", "Close Ad", "Fechar", "Fechar anúncio"] where app.buttons[name].exists {
            app.buttons[name].tap()
            return
        }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.08)).tap()
    }
}
