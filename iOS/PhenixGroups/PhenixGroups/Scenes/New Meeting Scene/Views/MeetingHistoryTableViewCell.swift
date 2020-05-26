//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class MeetingHistoryTableViewCell: UITableViewCell, CellIdentified {
    typealias RejoinHandler = MeetingHistoryTableViewController.RejoinHandler

    private var codeLabel: UILabel!
    private var leaveTimeLabel: UILabel!
    private var rejoinButton: UIButton!

    private var meeting: Meeting!
    private var rejoinHandler: RejoinHandler?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func configure(with model: Meeting, rejoin: RejoinHandler?) {
        self.meeting = model

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        codeLabel.text = model.code
        leaveTimeLabel.text = "Left at \(dateFormatter.string(from: model.leaveDate))"
        rejoinHandler = rejoin
    }

    @objc
    func rejoinButtonTapped(_ sender: Any) {
        rejoinHandler?(meeting)
    }
}

private extension MeetingHistoryTableViewCell {
    func commonInit() {
        setupLabels()
        setupButton()
        setupConstraints()
    }

    func setupLabels() {
        codeLabel = UILabel.mainLabel
        leaveTimeLabel = UILabel.secondaryLabel

        contentView.addSubview(codeLabel)
        contentView.addSubview(leaveTimeLabel)
    }

    func setupButton() {
        rejoinButton = UIButton.mainButton(title: "Rejoin")
        rejoinButton.addTarget(self, action: #selector(rejoinButtonTapped), for: .touchUpInside)
        rejoinButton.setContentHuggingPriority(.defaultLow, for: .horizontal)

        contentView.addSubview(rejoinButton)
    }

    func setupConstraints() {
        // swiftlint:disable multiline_arguments_brackets
        NSLayoutConstraint.activate([
            codeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            codeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            codeLabel.bottomAnchor.constraint(equalTo: leaveTimeLabel.topAnchor, constant: -5),
            leaveTimeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            leaveTimeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            rejoinButton.leadingAnchor.constraint(greaterThanOrEqualTo: codeLabel.trailingAnchor, constant: 10),
            rejoinButton.leadingAnchor.constraint(greaterThanOrEqualTo: leaveTimeLabel.trailingAnchor, constant: 10),
            rejoinButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rejoinButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
