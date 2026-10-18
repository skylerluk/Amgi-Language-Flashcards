import XCTest

@MainActor
final class ReadingFlowTests: XCTestCase {
    func testMandarinBooksAndConversationNavigation() throws {
        let app = XCUIApplication()
        app.launch()
        let skip = app.buttons["Skip"]
        if skip.waitForExistence(timeout: 3) { skip.tap() }
        let local = app.buttons["Use Locally"]
        if local.waitForExistence(timeout: 3) { local.tap() }
        let read = app.tabBars.buttons["Read"]
        XCTAssertTrue(read.waitForExistence(timeout: 20))
        read.tap()
        let book = app.staticTexts["小区里的秘密 · HSK 3–4"].firstMatch
        XCTAssertTrue(book.waitForExistence(timeout: 20))
        attach(app, name: "Mandarin bookshelf")
        app.segmentedControls.buttons["Conversations"].tap()
        let dialogue = app.staticTexts["好久不见，最近怎么样？"].firstMatch
        XCTAssertTrue(dialogue.waitForExistence(timeout: 5))
        dialogue.tap()
        XCTAssertTrue(app.buttons["Show translations"].waitForExistence(timeout: 5))
        app.buttons["Show translations"].tap()
        attach(app, name: "Mandarin dialogue")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.segmentedControls.buttons["Books"].tap()
        XCTAssertTrue(book.waitForExistence(timeout: 5))
        book.tap()
        XCTAssertTrue(app.staticTexts["一、奇怪的纸条"].waitForExistence(timeout: 5))
        app.staticTexts["一、奇怪的纸条"].tap()
        XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 10))
        let sentence = app.webViews.staticTexts["星"].firstMatch
        XCTAssertTrue(sentence.waitForExistence(timeout: 10))
        attach(app, name: "Chinese chapter")
        sentence.tap()
        let save = app.buttons["Save card"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        save.tap()
        XCTAssertTrue(app.staticTexts["Saved"].waitForExistence(timeout: 10))
        attach(app, name: "Saved Chinese sentence")
        app.buttons["Undo"].tap()
        XCTAssertTrue(save.waitForExistence(timeout: 5))
    }

    private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
