import Foundation

enum AccessibilityID {
    static let studentList = "studentList"
    static let studentDetails = "studentDetails"
    static let addStudentButton = "addStudentButton"
    static let editStudentButton = "editStudentButton"
    static let studentNameField = "studentNameField"
    static let studentAgeField = "studentAgeField"
    static let saveStudentButton = "saveStudentButton"
    static let cancelStudentButton = "cancelStudentButton"
    static let studentFormError = "studentFormError"

    static func studentCell(_ id: UUID) -> String { "studentCell.\(id.uuidString)" }
    static func subjectButton(_ subject: String) -> String { "subjectButton.\(subject)" }
    static func detailValue(_ field: String) -> String { "studentDetails.\(field)" }
}
