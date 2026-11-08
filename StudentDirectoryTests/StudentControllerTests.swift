import UIKit
import XCTest
@testable import StudentDirectory

@MainActor
final class StudentControllerTests: XCTestCase {
    private func seedID(_ suffix: String) -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-0000000000\(suffix)") ?? UUID()
    }

    private var hostWindow: UIWindow?

    override func tearDown() {
        hostWindow?.isHidden = true
        hostWindow = nil
        super.tearDown()
    }

    private func host(_ root: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: root)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        root.view.layoutIfNeeded()
        hostWindow = window
        return navigationController
    }

    private func findView(in root: UIView, identifier: String) -> UIView? {
        if root.accessibilityIdentifier == identifier { return root }
        for subview in root.subviews {
            if let match = findView(in: subview, identifier: identifier) { return match }
        }
        return nil
    }

    private func label(in controller: UIViewController, field: String) -> UILabel? {
        findView(in: controller.view, identifier: AccessibilityID.detailValue(field)) as? UILabel
    }

    func testMainListShowsSeedStudentsWithIdentifiers() {
        let list = StudentListViewController(store: StudentStore())
        _ = host(list)

        XCTAssertEqual(list.title, "Students")
        XCTAssertEqual(list.tableView.accessibilityIdentifier, "studentList")
        XCTAssertEqual(list.tableView.numberOfRows(inSection: 0), 10)
        let cell = list.tableView.cellForRow(at: IndexPath(row: 0, section: 0))
        XCTAssertTrue(cell is StudentTableViewCell)
        XCTAssertEqual(cell?.accessibilityIdentifier, "studentCell.00000000-0000-0000-0000-000000000001")
        XCTAssertEqual(list.navigationItem.rightBarButtonItem?.accessibilityIdentifier, "addStudentButton")
    }

    func testSubjectListShowsFilteredStudentsWithoutAddButton() {
        let list = StudentListViewController(store: StudentStore(), filter: .subject("Physics"))
        _ = host(list)

        XCTAssertEqual(list.title, "Physics")
        XCTAssertEqual(list.tableView.numberOfRows(inSection: 0), 4)
        XCTAssertEqual(
            list.displayedStudents.map(\.name),
            ["Alan Turing", "Katherine Johnson", "Mary Jackson", "Tim Berners-Lee"]
        )
        XCTAssertNil(list.navigationItem.rightBarButtonItem)
    }

    func testSelectingRowPushesDetailForThatStudent() {
        let list = StudentListViewController(store: StudentStore())
        let navigationController = host(list)

        list.tableView(list.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))

        let detail = navigationController.viewControllers.last as? StudentDetailViewController
        XCTAssertNotNil(detail)
        XCTAssertEqual(detail?.studentID, seedID("02"))
    }

    func testDetailShowsStudentFields() {
        let detail = StudentDetailViewController(store: StudentStore(), studentID: seedID("01"))
        _ = host(detail)

        XCTAssertEqual(detail.view.accessibilityIdentifier, "studentDetails")
        XCTAssertEqual(detail.title, "Ada Lovelace")
        XCTAssertEqual(label(in: detail, field: "id")?.text, "00000000-0000-0000-0000-000000000001")
        XCTAssertEqual(label(in: detail, field: "name")?.text, "Ada Lovelace")
        XCTAssertEqual(label(in: detail, field: "age")?.text, "20")
        XCTAssertEqual(label(in: detail, field: "averageGrade")?.text, "97.5")
        XCTAssertEqual(label(in: detail, field: "scholarship")?.text, "Scholarship holder")
        XCTAssertEqual(label(in: detail, field: "avatarName")?.text, "avatar-01")
        for subject in ["Algorithms", "Math", "Design"] {
            let button = findView(in: detail.view, identifier: "subjectButton.\(subject)")
            XCTAssertTrue(button is UIButton, "Missing subject button for \(subject)")
        }
        XCTAssertEqual(detail.navigationItem.rightBarButtonItem?.accessibilityIdentifier, "editStudentButton")
    }

    func testTappingSubjectButtonPushesFilteredList() {
        let store = StudentStore()
        let detail = StudentDetailViewController(store: store, studentID: seedID("01"))
        let navigationController = host(detail)

        let button = findView(in: detail.view, identifier: "subjectButton.Math") as? UIButton
        XCTAssertNotNil(button)
        button?.sendActions(for: .touchUpInside)

        let list = navigationController.viewControllers.last as? StudentListViewController
        XCTAssertNotNil(list)
        XCTAssertEqual(list?.filter, .subject("Math"))
        list?.loadViewIfNeeded()
        XCTAssertEqual(list?.title, "Math")
    }

    func testDetailRefreshesAfterStoreUpdate() throws {
        let store = StudentStore()
        let detail = StudentDetailViewController(store: store, studentID: seedID("01"))
        _ = host(detail)

        try store.updateStudent(id: seedID("01"), name: "Ada King", age: 30)

        XCTAssertEqual(label(in: detail, field: "name")?.text, "Ada King")
        XCTAssertEqual(label(in: detail, field: "age")?.text, "30")
        XCTAssertEqual(detail.title, "Ada King")
    }

    func testMainListRowCountFollowsStore() throws {
        let store = StudentStore()
        let list = StudentListViewController(store: store)
        _ = host(list)

        XCTAssertEqual(list.tableView.numberOfRows(inSection: 0), 10)
        try store.addStudent(name: "Margaret Hamilton", age: 33)
        XCTAssertEqual(list.tableView.numberOfRows(inSection: 0), 11)
        let added = try XCTUnwrap(store.students.last)
        try store.deleteStudent(id: added.id)
        XCTAssertEqual(list.tableView.numberOfRows(inSection: 0), 10)
    }

    func testFormWithNonNumericAgeShowsErrorAndDoesNotSubmit() {
        var submitCount = 0
        let form = StudentFormViewController(mode: .add) { _, _ in
            submitCount += 1
        }
        _ = host(form)

        form.nameField.text = "Grace"
        form.ageField.text = "abc"
        form.submit()

        XCTAssertEqual(submitCount, 0)
        XCTAssertFalse(form.errorLabel.isHidden)
        XCTAssertEqual(form.errorLabel.text, "Enter the age as a whole number greater than zero.")
    }

    func testFormShowsStoreValidationErrorForBlankName() {
        let store = StudentStore()
        let form = StudentFormViewController(mode: .add) { name, age in
            try store.addStudent(name: name, age: age)
        }
        _ = host(form)

        form.nameField.text = "   "
        form.ageField.text = "20"
        form.submit()

        XCTAssertFalse(form.errorLabel.isHidden)
        XCTAssertEqual(form.errorLabel.text, "Name can't be blank.")
        XCTAssertEqual(store.students.count, 10)
    }

    func testEditFormPrefillsFieldsAndTitle() {
        let form = StudentFormViewController(mode: .edit(name: "Ada Lovelace", age: 20)) { _, _ in }
        _ = host(form)

        XCTAssertEqual(form.title, "Edit Student")
        XCTAssertEqual(form.nameField.text, "Ada Lovelace")
        XCTAssertEqual(form.ageField.text, "20")
    }
}
