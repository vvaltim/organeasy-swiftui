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

        let unlock = app.buttons["unlockAI"]
        XCTAssertTrue(unlock.waitForExistence(timeout: 5))
        unlock.tap()
        pause(8)
        capture("ads_3_video")
        pause(32)
        capture("ads_4_video_fim")
    }
}
