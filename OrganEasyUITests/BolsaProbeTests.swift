import XCTest

final class BolsaProbeTests: XCTestCase {
    func testBolsaTab() {
        let env = ProcessInfo.processInfo.environment
        let dir = env["CAPTURE_DIR"] ?? NSTemporaryDirectory()
        let prefix = env["CAPTURE_PREFIX"] ?? "bolsa"
        let app = XCUIApplication()
        var args = ["-showcase"]
        if let language = env["CAPTURE_LANG"], let locale = env["CAPTURE_LOCALE"] {
            args += ["-AppleLanguages", "(\(language))", "-AppleLocale", locale]
        }
        app.launchArguments = args
        app.launch()

        func capture(_ name: String) {
            try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(prefix)_\(name).png"))
        }
        func tab(_ names: [String]) -> XCUIElement {
            app.buttons.matching(NSPredicate(format: "label IN %@", names)).firstMatch
        }

        tab(["Bolsa", "Stocks", "Bourse", "Borsa"]).tap()
        let desk = app.buttons.matching(identifier: "bolsaDesk").firstMatch
        XCTAssertTrue(desk.waitForExistence(timeout: 40))
        Thread.sleep(forTimeInterval: 1.5)
        capture("1_escritorio")
        let count = app.buttons.matching(identifier: "bolsaDesk").count
        XCTAssertLessThanOrEqual(count, 12)
        XCTAssertGreaterThan(count, 0)

        app.swipeUp()
        Thread.sleep(forTimeInterval: 1)
        capture("2_rolagem")
        app.swipeDown()
        Thread.sleep(forTimeInterval: 1)

        app.buttons.matching(identifier: "bolsaDesk").firstMatch.tap()
        let open = app.buttons.matching(NSPredicate(format: "label IN %@", ["Ver em Investimentos", "View in Investments"])).firstMatch
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1)
        capture("3_cartao")
        open.tap()
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertTrue(tab(["Investimentos", "Investments"]).isSelected)
        capture("4_investimentos")
    }
}
