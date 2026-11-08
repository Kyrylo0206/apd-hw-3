import SnapKit
import UIKit

final class StudentDetailViewController: UIViewController {
    let store: StudentStore
    let studentID: UUID

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let avatarImageView = UIImageView()
    private let subjectsStack = UIStackView()
    private var valueLabels: [String: UILabel] = [:]
    private let editItem = UIBarButtonItem(systemItem: .edit)

    private let fields: [(key: String, caption: String)] = [
        ("id", "Student ID"),
        ("name", "Name"),
        ("age", "Age"),
        ("averageGrade", "Average grade"),
        ("scholarship", "Scholarship"),
        ("avatarName", "Avatar")
    ]

    init(store: StudentStore, studentID: UUID) {
        self.store = store
        self.studentID = studentID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = AccessibilityID.studentDetails
        navigationItem.largeTitleDisplayMode = .never

        editItem.primaryAction = UIAction { [weak self] _ in
            self?.presentEditForm()
        }
        editItem.accessibilityIdentifier = AccessibilityID.editStudentButton
        editItem.accessibilityLabel = "Edit student"
        navigationItem.rightBarButtonItem = editItem

        buildLayout()
        reloadContent()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeDidChange),
            name: StudentStore.didChangeNotification,
            object: store
        )
    }

    @objc private func storeDidChange() {
        reloadContent()
    }

    func reloadContent() {
        guard let student = store.student(withID: studentID) else {
            title = "Student unavailable"
            scrollView.isHidden = true
            editItem.isEnabled = false
            return
        }
        scrollView.isHidden = false
        editItem.isEnabled = true
        title = student.name

        avatarImageView.image = StudentFormatter.avatarImage(named: student.avatarName)
        avatarImageView.accessibilityLabel = "Avatar of \(student.name)"

        valueLabels["id"]?.text = student.id.uuidString
        valueLabels["name"]?.text = student.name
        valueLabels["age"]?.text = "\(student.age)"
        valueLabels["averageGrade"]?.text = StudentFormatter.gradeValue(student.averageGrade)
        valueLabels["scholarship"]?.text = StudentFormatter.scholarshipText(student.isScholarshipHolder)
        valueLabels["avatarName"]?.text = student.avatarName

        reloadSubjects(student.subjects)
    }

    private func reloadSubjects(_ subjects: [String]) {
        subjectsStack.arrangedSubviews.forEach { view in
            subjectsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        if subjects.isEmpty {
            let label = makeLabel(textStyle: .body, color: .secondaryLabel)
            label.text = "No subjects"
            subjectsStack.addArrangedSubview(label)
            return
        }
        for subject in subjects {
            let button = UIButton(configuration: .tinted())
            button.configuration?.title = subject
            button.contentHorizontalAlignment = .leading
            button.accessibilityIdentifier = AccessibilityID.subjectButton(subject)
            button.accessibilityHint = "Shows students who take \(subject)"
            button.addAction(UIAction { [weak self] _ in
                self?.showStudents(for: subject)
            }, for: .touchUpInside)
            subjectsStack.addArrangedSubview(button)
        }
    }

    private func buildLayout() {
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStack.axis = .vertical
        contentStack.spacing = 16
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(20)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-40)
        }

        avatarImageView.layer.cornerRadius = 48
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.isAccessibilityElement = true
        avatarImageView.accessibilityTraits = .image
        let avatarContainer = UIView()
        avatarContainer.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.size.equalTo(96)
            make.top.bottom.leading.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        contentStack.addArrangedSubview(avatarContainer)

        for field in fields {
            let caption = makeLabel(textStyle: .footnote, color: .secondaryLabel)
            caption.text = field.caption
            let value = makeLabel(textStyle: .body, color: .label)
            value.accessibilityIdentifier = AccessibilityID.detailValue(field.key)
            valueLabels[field.key] = value
            let stack = UIStackView(arrangedSubviews: [caption, value])
            stack.axis = .vertical
            stack.spacing = 2
            contentStack.addArrangedSubview(stack)
        }

        let subjectsCaption = makeLabel(textStyle: .headline, color: .label)
        subjectsCaption.text = "Subjects"
        subjectsCaption.accessibilityTraits = .header
        contentStack.addArrangedSubview(subjectsCaption)

        subjectsStack.axis = .vertical
        subjectsStack.spacing = 8
        contentStack.addArrangedSubview(subjectsStack)
    }

    private func makeLabel(textStyle: UIFont.TextStyle, color: UIColor) -> UILabel {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: textStyle)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = color
        return label
    }

    private func showStudents(for subject: String) {
        let list = StudentListViewController(store: store, filter: .subject(subject))
        navigationController?.pushViewController(list, animated: true)
    }

    private func presentEditForm() {
        guard let student = store.student(withID: studentID) else { return }
        let form = StudentFormViewController(mode: .edit(name: student.name, age: student.age)) { [weak self] name, age in
            guard let self else { return }
            try self.store.updateStudent(id: self.studentID, name: name, age: age)
        }
        present(UINavigationController(rootViewController: form), animated: true)
    }
}
