import SnapKit
import UIKit

final class StudentTableViewCell: UITableViewCell {
    static let reuseIdentifier = "StudentTableViewCell"

    private let avatarImageView = UIImageView()
    private let nameLabel = UILabel()
    private let ageLabel = UILabel()
    private let gradeLabel = UILabel()
    private let scholarshipLabel = UILabel()
    private let textStack = UIStackView()
    private let rowStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpViews()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (cell: StudentTableViewCell, _) in
            cell.updateLayoutAxis()
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
    }

    func configure(with student: Student) {
        nameLabel.text = student.name
        ageLabel.text = StudentFormatter.ageText(student.age)
        gradeLabel.text = StudentFormatter.gradeText(student.averageGrade)
        scholarshipLabel.text = StudentFormatter.scholarshipText(student.isScholarshipHolder)
        scholarshipLabel.textColor = student.isScholarshipHolder ? .label : .secondaryLabel
        avatarImageView.image = StudentFormatter.avatarImage(named: student.avatarName)
        accessibilityIdentifier = AccessibilityID.studentCell(student.id)
    }

    private func setUpViews() {
        accessoryType = .disclosureIndicator

        avatarImageView.layer.cornerRadius = 28
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.isAccessibilityElement = false

        style(nameLabel, textStyle: .headline, color: .label)
        style(ageLabel, textStyle: .subheadline, color: .secondaryLabel)
        style(gradeLabel, textStyle: .subheadline, color: .secondaryLabel)
        style(scholarshipLabel, textStyle: .footnote, color: .secondaryLabel)

        textStack.axis = .vertical
        textStack.spacing = 4
        [nameLabel, ageLabel, gradeLabel, scholarshipLabel].forEach { textStack.addArrangedSubview($0) }

        rowStack.spacing = 12
        rowStack.addArrangedSubview(avatarImageView)
        rowStack.addArrangedSubview(textStack)
        contentView.addSubview(rowStack)

        rowStack.snp.makeConstraints { make in
            make.edges.equalTo(contentView.layoutMarginsGuide)
        }
        avatarImageView.snp.makeConstraints { make in
            make.size.equalTo(56)
        }
        updateLayoutAxis()
    }

    private func style(_ label: UILabel, textStyle: UIFont.TextStyle, color: UIColor) {
        label.font = UIFont.preferredFont(forTextStyle: textStyle)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = color
    }

    private func updateLayoutAxis() {
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            rowStack.axis = .vertical
            rowStack.alignment = .leading
        } else {
            rowStack.axis = .horizontal
            rowStack.alignment = .top
        }
    }
}
