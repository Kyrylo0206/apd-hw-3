import SnapKit
import UIKit

final class StudentFormViewController: UIViewController, UITextFieldDelegate {
    enum Mode: Equatable {
        case add
        case edit(name: String, age: Int)
    }

    let mode: Mode
    let nameField = UITextField()
    let ageField = UITextField()
    let errorLabel = UILabel()
    private let onSubmit: (String, Int) throws -> Void

    init(mode: Mode, onSubmit: @escaping (String, Int) throws -> Void) {
        self.mode = mode
        self.onSubmit = onSubmit
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        switch mode {
        case .add:
            title = "New Student"
        case .edit(let name, let age):
            title = "Edit Student"
            nameField.text = name
            ageField.text = String(age)
        }

        let cancelItem = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })
        cancelItem.accessibilityIdentifier = AccessibilityID.cancelStudentButton
        navigationItem.leftBarButtonItem = cancelItem

        let saveItem = UIBarButtonItem(systemItem: .save, primaryAction: UIAction { [weak self] _ in
            self?.submit()
        })
        saveItem.accessibilityIdentifier = AccessibilityID.saveStudentButton
        navigationItem.rightBarButtonItem = saveItem

        configureFields()
        buildLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameField.becomeFirstResponder()
    }

    func submit() {
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let ageText = (ageField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let age = Int(ageText) else {
            showError("Enter the age as a whole number greater than zero.")
            return
        }
        do {
            try onSubmit(name, age)
            dismiss(animated: true)
        } catch let error as StudentStoreError {
            showError(message(for: error))
        } catch {
            showError("Something went wrong. Please try again.")
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === nameField {
            ageField.becomeFirstResponder()
        }
        return false
    }

    private func message(for error: StudentStoreError) -> String {
        switch error {
        case .blankName:
            return "Name can't be blank."
        case .nonPositiveAge:
            return "Age must be greater than zero."
        case .unknownID:
            return "This student no longer exists."
        }
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    private func configureFields() {
        nameField.placeholder = "Name"
        nameField.borderStyle = .roundedRect
        nameField.font = UIFont.preferredFont(forTextStyle: .body)
        nameField.adjustsFontForContentSizeCategory = true
        nameField.autocapitalizationType = .words
        nameField.autocorrectionType = .no
        nameField.clearButtonMode = .whileEditing
        nameField.returnKeyType = .next
        nameField.delegate = self
        nameField.accessibilityIdentifier = AccessibilityID.studentNameField
        nameField.accessibilityLabel = "Name"

        ageField.placeholder = "Age"
        ageField.borderStyle = .roundedRect
        ageField.font = UIFont.preferredFont(forTextStyle: .body)
        ageField.adjustsFontForContentSizeCategory = true
        ageField.keyboardType = .numberPad
        ageField.clearButtonMode = .whileEditing
        ageField.accessibilityIdentifier = AccessibilityID.studentAgeField
        ageField.accessibilityLabel = "Age"

        errorLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        errorLabel.accessibilityIdentifier = AccessibilityID.studentFormError
    }

    private func buildLayout() {
        let stack = UIStackView(arrangedSubviews: [
            makeCaption("Name"),
            nameField,
            makeCaption("Age"),
            ageField,
            errorLabel
        ])
        stack.axis = .vertical
        stack.spacing = 8
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-20)
        }
    }

    private func makeCaption(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }
}
