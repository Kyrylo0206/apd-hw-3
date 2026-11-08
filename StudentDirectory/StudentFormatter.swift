import UIKit

enum StudentFormatter {
    static func ageText(_ age: Int) -> String {
        "Age \(age)"
    }

    static func gradeValue(_ grade: Double) -> String {
        String(format: "%.1f", grade)
    }

    static func gradeText(_ grade: Double) -> String {
        "Average grade \(gradeValue(grade))"
    }

    static func scholarshipText(_ isHolder: Bool) -> String {
        isHolder ? "Scholarship holder" : "No scholarship"
    }

    static func avatarImage(named name: String) -> UIImage? {
        UIImage(named: name) ?? UIImage(named: "avatar-default")
    }
}
