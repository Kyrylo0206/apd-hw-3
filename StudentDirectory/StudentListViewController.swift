import SnapKit
import UIKit

final class StudentListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    enum Filter: Equatable {
        case all
        case subject(String)
    }

    let store: StudentStore
    let filter: Filter
    let tableView = UITableView(frame: .zero, style: .plain)

    var displayedStudents: [Student] {
        switch filter {
        case .all:
            return store.students
        case .subject(let subject):
            return store.students(matchingSubject: subject)
        }
    }

    init(store: StudentStore, filter: Filter = .all) {
        self.store = store
        self.filter = filter
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
        switch filter {
        case .all:
            title = "Students"
            let addItem = UIBarButtonItem(systemItem: .add, primaryAction: UIAction { [weak self] _ in
                self?.presentAddForm()
            })
            addItem.accessibilityIdentifier = AccessibilityID.addStudentButton
            addItem.accessibilityLabel = "Add student"
            navigationItem.rightBarButtonItem = addItem
        case .subject(let subject):
            title = subject
        }
        view.backgroundColor = .systemBackground

        tableView.accessibilityIdentifier = AccessibilityID.studentList
        tableView.register(StudentTableViewCell.self, forCellReuseIdentifier: StudentTableViewCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 96
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeDidChange),
            name: StudentStore.didChangeNotification,
            object: store
        )
    }

    @objc private func storeDidChange() {
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedStudents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: StudentTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? StudentTableViewCell else {
            return UITableViewCell()
        }
        let students = displayedStudents
        if indexPath.row < students.count {
            cell.configure(with: students[indexPath.row])
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let students = displayedStudents
        guard indexPath.row < students.count else { return }
        let detail = StudentDetailViewController(store: store, studentID: students[indexPath.row].id)
        navigationController?.pushViewController(detail, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard filter == .all else { return nil }
        let students = displayedStudents
        guard indexPath.row < students.count else { return nil }
        let student = students[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }
            do {
                try self.store.deleteStudent(id: student.id)
                completion(true)
            } catch {
                completion(false)
            }
        }
        let configuration = UISwipeActionsConfiguration(actions: [delete])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    private func presentAddForm() {
        let form = StudentFormViewController(mode: .add) { [weak self] name, age in
            guard let self else { return }
            try self.store.addStudent(name: name, age: age)
            self.scrollToLastRow()
        }
        present(UINavigationController(rootViewController: form), animated: true)
    }

    private func scrollToLastRow() {
        let count = tableView.numberOfRows(inSection: 0)
        guard count > 0 else { return }
        tableView.scrollToRow(at: IndexPath(row: count - 1, section: 0), at: .bottom, animated: false)
    }
}
