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
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
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
    func setup() {
        codeLabel = UILabel.primaryLabel
        leaveTimeLabel = UILabel.secondaryLabel
        rejoinButton = UIButton.makePrimaryButton(withTitle: "Rejoin")
        rejoinButton.addTarget(self, action: #selector(rejoinButtonTapped), for: .touchUpInside)
        rejoinButton.setContentHuggingPriority(.required, for: .horizontal)
        rejoinButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        contentView.addSubview(codeLabel)
        contentView.addSubview(leaveTimeLabel)
        contentView.addSubview(rejoinButton)

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
