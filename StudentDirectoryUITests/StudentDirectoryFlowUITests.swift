import XCTest

@MainActor
final class StudentDirectoryFlowUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        return app
    }

    private func cellID(_ suffix: String) -> String {
        "studentCell.00000000-0000-0000-0000-0000000000\(suffix)"
    }

    private func openAddForm(in app: XCUIApplication) {
        let addButton = app.buttons["addStudentButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
        XCTAssertTrue(app.textFields["studentNameField"].waitForExistence(timeout: 5))
    }

    func testListShowsSeedStudents() {
        let app = launchApp()
        XCTAssertTrue(app.navigationBars["Students"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tables["studentList"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.cells[cellID("01")].waitForExistence(timeout: 5))
        XCTAssertTrue(app.cells[cellID("01")].staticTexts["Ada Lovelace"].exists)
    }

    func testTappingStudentShowsDetailsAndBackReturnsToList() {
        let app = launchApp()
        let cell = app.cells[cellID("02")]
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        cell.tap()

        XCTAssertTrue(app.otherElements["studentDetails"].waitForExistence(timeout: 5))
        let nameLabel = app.staticTexts["studentDetails.name"]
        XCTAssertTrue(nameLabel.waitForExistence(timeout: 5))
        XCTAssertEqual(nameLabel.label, "Alan Turing")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Students"].waitForExistence(timeout: 5))
    }

    func testSubjectButtonShowsFilteredList() {
        let app = launchApp()
        let cell = app.cells[cellID("01")]
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        cell.tap()

        let subjectButton = app.buttons["subjectButton.Math"]
        XCTAssertTrue(subjectButton.waitForExistence(timeout: 5))
        subjectButton.tap()

        XCTAssertTrue(app.navigationBars["Math"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.cells[cellID("01")].waitForExistence(timeout: 5))
        XCTAssertTrue(app.cells[cellID("04")].exists)
        XCTAssertTrue(app.cells[cellID("07")].exists)
        XCTAssertFalse(app.cells[cellID("02")].exists)
    }

    func testAddStudentAppearsInList() {
        let app = launchApp()
        openAddForm(in: app)

        let nameField = app.textFields["studentNameField"]
        nameField.tap()
        nameField.typeText("Margaret Hamilton")
        let ageField = app.textFields["studentAgeField"]
        ageField.tap()
        ageField.typeText("33")
        app.buttons["saveStudentButton"].tap()

        XCTAssertTrue(app.navigationBars["Students"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.cells.staticTexts["Margaret Hamilton"].waitForExistence(timeout: 5))
    }

    func testInvalidAddShowsErrorAndCancelReturnsToList() {
        let app = launchApp()
        openAddForm(in: app)

        let ageField = app.textFields["studentAgeField"]
        ageField.tap()
        ageField.typeText("20")
        app.buttons["saveStudentButton"].tap()

        XCTAssertTrue(app.staticTexts["studentFormError"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["saveStudentButton"].exists)

        app.buttons["cancelStudentButton"].tap()
        XCTAssertTrue(app.navigationBars["Students"].waitForExistence(timeout: 5))
    }

    func testEditStudentNameUpdatesDetailsAndList() {
        let app = launchApp()
        let cell = app.cells[cellID("01")]
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        cell.tap()

        let editButton = app.buttons["editStudentButton"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        let nameField = app.textFields["studentNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        let clearButton = nameField.buttons["Clear text"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5))
        clearButton.tap()
        nameField.typeText("Ada King")
        app.buttons["saveStudentButton"].tap()

        let nameLabel = app.staticTexts["studentDetails.name"]
        XCTAssertTrue(nameLabel.waitForExistence(timeout: 5))
        XCTAssertEqual(nameLabel.label, "Ada King")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Students"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.cells[cellID("01")].staticTexts["Ada King"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.cells[cellID("01")].staticTexts["Ada Lovelace"].exists)
    }

    func testSwipeToDeleteRemovesStudent() {
        let app = launchApp()
        let cell = app.cells[cellID("01")]
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        cell.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        XCTAssertTrue(cell.waitForNonExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Ada Lovelace"].exists)
    }
}
