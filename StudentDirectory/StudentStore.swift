import Foundation

final class StudentStore {
    static let didChangeNotification = Notification.Name("StudentStore.didChange")

    private(set) var students: [Student]

    init(students: [Student] = StudentSeedData.students) {
        self.students = students
    }

    func student(withID id: UUID) -> Student? {
        students.first { $0.id == id }
    }

    func students(matchingSubject subject: String) -> [Student] {
        students.filter { $0.subjects.contains(subject) }
    }

    func addStudent(name: String, age: Int) throws {
        try validate(name: name, age: age)
        students.append(Student(id: UUID(), name: name, age: age, averageGrade: 0, isScholarshipHolder: false, subjects: [], avatarName: "avatar-default"))
        postDidChange()
    }

    func updateStudent(id: UUID, name: String, age: Int) throws {
        try validate(name: name, age: age)
        guard let index = students.firstIndex(where: { $0.id == id }) else {
            throw StudentStoreError.unknownID(id)
        }
        students[index].name = name
        students[index].age = age
        postDidChange()
    }

    func deleteStudent(id: UUID) throws {
        guard let index = students.firstIndex(where: { $0.id == id }) else {
            throw StudentStoreError.unknownID(id)
        }
        students.remove(at: index)
        postDidChange()
    }

    private func postDidChange() {
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }

    private func validate(name: String, age: Int) throws {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw StudentStoreError.blankName
        }
        if age <= 0 {
            throw StudentStoreError.nonPositiveAge
        }
    }
}
