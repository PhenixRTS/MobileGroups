//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Combine
import UIKit

class ActiveMeetingChatTableViewCell: UITableViewCell, CellIdentified {
    private lazy var displayNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .footnote, compatibleWith: .init(legibilityWeight: .bold))
        label.textColor = .label
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return label
    }()

    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.textAlignment = .left
        return label
    }()

    private lazy var messageTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .preferredFont(forTextStyle: .footnote)
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.textContainerInset = .zero
        textView.isScrollEnabled = false
        textView.isEditable = false
        // Data detector takes a lot of time to evaluate the text,
        // so it can result in application freeze for some time
        // while the LLDB is attached for some reason.
        textView.dataDetectorTypes = [.link, .phoneNumber]
        textView.textColor = .label
        return textView
    }()

    private var viewModel: ViewModel?
    private var cancellable: AnyCancellable?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(viewModel: ViewModel) {
        self.viewModel = viewModel

        displayNameLabel.text = viewModel.author
        messageTextView.text = viewModel.text
        dateLabel.text = viewModel.localizedDate

        cancellable = viewModel.localizedDatePublisher
            .sink { [weak self] localizedDate in
                self?.dateLabel.text = localizedDate
            }
    }
}

private extension ActiveMeetingChatTableViewCell {
    func setup() {
        contentView.addSubview(displayNameLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(messageTextView)

        NSLayoutConstraint.activate([
            displayNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            displayNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),

            dateLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: displayNameLabel.trailingAnchor, constant: 10),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            dateLabel.lastBaselineAnchor.constraint(equalTo: displayNameLabel.lastBaselineAnchor),

            messageTextView.topAnchor.constraint(equalTo: displayNameLabel.bottomAnchor, constant: 0),
            messageTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            messageTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            messageTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
}
