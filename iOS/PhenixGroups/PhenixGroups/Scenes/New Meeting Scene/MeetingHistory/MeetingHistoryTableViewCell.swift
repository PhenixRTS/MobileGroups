//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class MeetingHistoryTableViewCell: UITableViewCell, CellIdentified {
    typealias JoinHandler = (Meeting) -> Void

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private lazy var codeLabel: UILabel = {
        let label = UILabel.primaryLabel
        return label
    }()

    private lazy var leaveTimeLabel: UILabel = {
        let label = UILabel.secondaryLabel
        label.text = "Left just now"
        return label
    }()

    private lazy var joinButton: UIButton = {
        let button = UIButton.makePrimaryButton(withTitle: "Rejoin")
        button.addTarget(self, action: #selector(rejoinButtonTapped), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    private var meeting: Meeting!
    private var onJoin: JoinHandler?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(with model: Meeting, onJoin: JoinHandler?) {
        self.meeting = model
        self.onJoin = onJoin

        codeLabel.text = model.code
        leaveTimeLabel.text = "Left at \(Self.dateFormatter.string(from: model.leaveDate))"
    }

    @objc
    func rejoinButtonTapped(_ sender: Any) {
        onJoin?(meeting)
    }

    // MARK: - Private methods

    func setup() {
        contentView.addSubview(codeLabel)
        contentView.addSubview(leaveTimeLabel)
        contentView.addSubview(joinButton)

        NSLayoutConstraint.activate([
            codeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            codeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            codeLabel.bottomAnchor.constraint(equalTo: leaveTimeLabel.topAnchor, constant: -5),
            leaveTimeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            leaveTimeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            joinButton.leadingAnchor.constraint(greaterThanOrEqualTo: codeLabel.trailingAnchor, constant: 10),
            joinButton.leadingAnchor.constraint(greaterThanOrEqualTo: leaveTimeLabel.trailingAnchor, constant: 10),
            joinButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            joinButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
