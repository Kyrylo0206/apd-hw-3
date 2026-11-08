import Foundation
import XCTest
@testable import StudentDirectory

private final class ChangeCounter: NSObject {
    private(set) var count = 0

    @objc func handle(_ notification: Notification) {
        count += 1
    }
}

@MainActor
final class StudentStoreTests: XCTestCase {
    private func seedID(_ suffix: String) -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-0000000000\(suffix)") ?? UUID()
    }

    func testSubjectFilterReturnsExactMatchesInStoreOrder() {
        let store = StudentStore()
        XCTAssertEqual(
            store.students(matchingSubject: "Math").map(\.name),
            ["Ada Lovelace", "Katherine Johnson", "Donald Knuth"]
        )
        XCTAssertEqual(
            store.students(matchingSubject: "Physics").map(\.name),
            ["Alan Turing", "Katherine Johnson", "Mary Jackson", "Tim Berners-Lee"]
        )
    }

    func testSubjectFilterIsCaseSensitiveAndUnknownSubjectIsEmpty() {
        let store = StudentStore()
        XCTAssertTrue(store.students(matchingSubject: "math").isEmpty)
        XCTAssertTrue(store.students(matchingSubject: "MATH").isEmpty)
        XCTAssertTrue(store.students(matchingSubject: "Chemistry").isEmpty)
    }

    func testAddStudentAppendsAtTheEndWithDefaults() throws {
        let store = StudentStore()
        let before = store.students
        try store.addStudent(name: "Margaret Hamilton", age: 33)

        XCTAssertEqual(store.students.count, before.count + 1)
        XCTAssertEqual(Array(store.students.dropLast()), before)
        let added = try XCTUnwrap(store.students.last)
        XCTAssertFalse(before.contains { $0.id == added.id })
        XCTAssertEqual(added.name, "Margaret Hamilton")
        XCTAssertEqual(added.age, 33)
        XCTAssertEqual(added.averageGrade, 0)
        XCTAssertFalse(added.isScholarshipHolder)
        XCTAssertEqual(added.subjects, [])
        XCTAssertEqual(added.avatarName, "avatar-default")
    }

    func testAddStudentRejectsBlankName() {
        let store = StudentStore()
        let before = store.students
        XCTAssertThrowsError(try store.addStudent(name: "", age: 20)) { error in
            XCTAssertEqual(error as? StudentStoreError, .blankName)
        }
        XCTAssertThrowsError(try store.addStudent(name: "  \n ", age: 20)) { error in
            XCTAssertEqual(error as? StudentStoreError, .blankName)
        }
        XCTAssertEqual(store.students, before)
    }

    func testAddStudentRejectsNonPositiveAge() {
        let store = StudentStore()
        let before = store.students
        XCTAssertThrowsError(try store.addStudent(name: "Valid", age: 0)) { error in
            XCTAssertEqual(error as? StudentStoreError, .nonPositiveAge)
        }
        XCTAssertThrowsError(try store.addStudent(name: "Valid", age: -1)) { error in
            XCTAssertEqual(error as? StudentStoreError, .nonPositiveAge)
        }
        XCTAssertEqual(store.students, before)
    }

    func testUpdateStudentChangesOnlyNameAndAgeAtSameIndex() throws {
        let store = StudentStore()
        let before = store.students
        let target = seedID("04")
        let index = try XCTUnwrap(before.firstIndex { $0.id == target })
        try store.updateStudent(id: target, name: "Kate Johnson", age: 31)

        XCTAssertEqual(store.students.count, before.count)
        let updated = store.students[index]
        XCTAssertEqual(updated.id, before[index].id)
        XCTAssertEqual(updated.name, "Kate Johnson")
        XCTAssertEqual(updated.age, 31)
        XCTAssertEqual(updated.averageGrade, before[index].averageGrade)
        XCTAssertEqual(updated.isScholarshipHolder, before[index].isScholarshipHolder)
        XCTAssertEqual(updated.subjects, before[index].subjects)
        XCTAssertEqual(updated.avatarName, before[index].avatarName)
        for other in before.indices where other != index {
            XCTAssertEqual(store.students[other], before[other])
        }
    }

    func testUpdateStudentRejectsInvalidInputWithoutMutation() {
        let store = StudentStore()
        let before = store.students
        let target = seedID("01")
        let unknown = seedID("99")

        XCTAssertThrowsError(try store.updateStudent(id: target, name: "  ", age: 20)) { error in
            XCTAssertEqual(error as? StudentStoreError, .blankName)
        }
        XCTAssertThrowsError(try store.updateStudent(id: target, name: "Ada", age: 0)) { error in
            XCTAssertEqual(error as? StudentStoreError, .nonPositiveAge)
        }
        XCTAssertThrowsError(try store.updateStudent(id: unknown, name: "Ada", age: 20)) { error in
            XCTAssertEqual(error as? StudentStoreError, .unknownID(unknown))
        }
        XCTAssertEqual(store.students, before)
    }

    func testDeleteStudentRemovesOnlyThatStudentAndPreservesOrder() throws {
        let store = StudentStore()
        let before = store.students
        let target = seedID("03")
        try store.deleteStudent(id: target)

        XCTAssertEqual(store.students, before.filter { $0.id != target })
        XCTAssertEqual(store.students.count, before.count - 1)
    }

    func testDeleteUnknownStudentThrowsWithoutMutation() {
        let store = StudentStore()
        let before = store.students
        let unknown = seedID("99")
        XCTAssertThrowsError(try store.deleteStudent(id: unknown)) { error in
            XCTAssertEqual(error as? StudentStoreError, .unknownID(unknown))
        }
        XCTAssertEqual(store.students, before)
    }

    func testStudentWithIDReturnsCurrentValueAndNilForUnknown() throws {
        let store = StudentStore()
        let target = seedID("01")
        XCTAssertEqual(store.student(withID: target)?.name, "Ada Lovelace")
        try store.updateStudent(id: target, name: "Ada King", age: 30)
        XCTAssertEqual(store.student(withID: target)?.name, "Ada King")
        XCTAssertEqual(store.student(withID: target)?.age, 30)
        XCTAssertNil(store.student(withID: seedID("99")))
    }

    func testSuccessfulMutationsPostExactlyOneNotificationEach() throws {
        let store = StudentStore()
        let counter = ChangeCounter()
        NotificationCenter.default.addObserver(
            counter,
            selector: #selector(ChangeCounter.handle(_:)),
            name: StudentStore.didChangeNotification,
            object: store
        )
        defer { NotificationCenter.default.removeObserver(counter) }

        try store.addStudent(name: "Margaret Hamilton", age: 33)
        XCTAssertEqual(counter.count, 1)
        try store.updateStudent(id: seedID("01"), name: "Ada King", age: 30)
        XCTAssertEqual(counter.count, 2)
        try store.deleteStudent(id: seedID("02"))
        XCTAssertEqual(counter.count, 3)
    }

    func testFailedMutationsPostNoNotification() {
        let store = StudentStore()
        let counter = ChangeCounter()
        NotificationCenter.default.addObserver(
            counter,
            selector: #selector(ChangeCounter.handle(_:)),
            name: StudentStore.didChangeNotification,
            object: store
        )
        defer { NotificationCenter.default.removeObserver(counter) }

        XCTAssertThrowsError(try store.addStudent(name: " ", age: 20))
        XCTAssertThrowsError(try store.addStudent(name: "Valid", age: 0))
        XCTAssertThrowsError(try store.updateStudent(id: seedID("01"), name: "", age: 20))
        XCTAssertThrowsError(try store.updateStudent(id: seedID("99"), name: "Valid", age: 20))
        XCTAssertThrowsError(try store.deleteStudent(id: seedID("99")))
        XCTAssertEqual(counter.count, 0)
    }
}
