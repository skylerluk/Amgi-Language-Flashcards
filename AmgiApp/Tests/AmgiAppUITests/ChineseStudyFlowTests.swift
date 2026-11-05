import XCTest

@MainActor final class ChineseStudyFlowTests: XCTestCase {
    func testHighlightedConversationWordsCanBeAdded() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Read"].tap()
        app.segmentedControls.buttons["Conversations"].tap()
        let dialogue = app.staticTexts["好久不见，最近怎么样？"].firstMatch
        XCTAssertTrue(dialogue.waitForExistence(timeout: 10))
        dialogue.tap()
        let text = app.textViews.firstMatch
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        text.press(forDuration: 1)
        let add = app.menuItems["Add selected text to deck"].firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 5), app.debugDescription)
        add.tap()
        XCTAssertTrue(app.navigationBars["Read & learn"].waitForExistence(timeout: 5))
        let save = app.buttons["Save card"]
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND enabled == true"), object: save)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 60), .completed, app.debugDescription)
        save.tap()
        XCTAssertTrue(app.staticTexts["Saved"].waitForExistence(timeout: 10))
        attach(app, "Selected Chinese vocabulary")
        app.buttons["Undo"].tap()
        XCTAssertTrue(save.waitForExistence(timeout: 5))
    }

    func testDeckControlsSelectedReviewAndProductionCard() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        if app.buttons["Skip"].waitForExistence(timeout: 2) { app.buttons["Skip"].tap() }
        if app.buttons["Use Locally"].waitForExistence(timeout: 2) { app.buttons["Use Locally"].tap() }
        app.tabBars.buttons["Library"].tap()
        let selection = app.buttons["Decks: 3"]
        XCTAssertTrue(selection.waitForExistence(timeout: 90), app.debugDescription)
        selection.tap()
        XCTAssertTrue(app.switches["Mandarin · HSK 3–4"].waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(app.switches["Mandarin · HSK 4–5"].exists)
        XCTAssertTrue(app.switches["Mandarin · Conversation phrases"].exists)
        app.buttons["Done"].tap()
        app.buttons["Daily cap: 40"].tap()
        XCTAssertTrue(app.staticTexts["40 card answers"].exists)
        app.buttons["Save"].tap()
        app.buttons["Start today's review"].tap()
        XCTAssertTrue(app.buttons["Show Answer"].waitForExistence(timeout: 15), app.debugDescription)
        app.buttons["Show Answer"].tap()
        let reverse = app.buttons["Add English → Chinese card"].firstMatch
        if reverse.waitForExistence(timeout: 2) { reverse.tap() }
        XCTAssertTrue(app.buttons["English → Chinese added"].firstMatch.waitForExistence(timeout: 10), app.debugDescription)
        attach(app, "Mandarin production card")
        app.buttons["Close"].firstMatch.tap()
        app.navigationBars.buttons["Add"].tap()
        app.buttons["New Deck"].tap()
        let field = app.textFields["Deck name, use :: for subdecks"]
        field.tap(); field.typeText("QA temporary")
        app.buttons["Create"].tap()
        let actions = app.buttons["Deck actions for QA temporary"]
        if !actions.isHittable { app.swipeUp() }
        XCTAssertTrue(actions.waitForExistence(timeout: 10))
        actions.tap(); app.buttons["Rename"].tap()
        let rename = app.textFields["Deck name"]
        rename.tap()
        rename.press(forDuration: 1)
        if app.menuItems["Select All"].exists { app.menuItems["Select All"].tap() }
        rename.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 12) + "QA renamed")
        app.buttons["Save"].tap()
        let renamed = app.buttons["Deck actions for QA renamed"]
        XCTAssertTrue(renamed.waitForExistence(timeout: 10))
        renamed.tap(); app.buttons["Delete"].tap()
        app.alerts.buttons["Delete"].tap()
        XCTAssertFalse(renamed.waitForExistence(timeout: 2))
        attach(app, "Mandarin library with study controls")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }
}
