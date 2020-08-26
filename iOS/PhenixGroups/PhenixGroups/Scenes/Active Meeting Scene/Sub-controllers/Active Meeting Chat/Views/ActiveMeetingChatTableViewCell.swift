//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

class ActiveMeetingChatTableViewCell: UITableViewCell, CellIdentified {
    private var displayNameLabel: UILabel!
    private var dateLabel: UILabel!
    private var messageTextView: UITextView!

    private var message: RoomChatMessage?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(message: RoomChatMessage) {
        self.message = message
        displayNameLabel.text = message.authorName
        dateLabel.text = message.date.localizedRelativeDateTime
        messageTextView.text = message.text
    }

    func refreshDateRepresentation() {
        dateLabel.text = message?.date.localizedRelativeDateTime
    }
}

private extension ActiveMeetingChatTableViewCell {
    func setup() {
        displayNameLabel = makeDisplayNameLabel()
        displayNameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        dateLabel = makeDateLabel()
        dateLabel.textAlignment = .left

        messageTextView = makeMessageTextView()

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

// MARK: - UI Element Factory methods
extension ActiveMeetingChatTableViewCell {
    func makeDisplayNameLabel() -> UILabel {
        let label = UILabel()

        label.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            label.font = .preferredFont(forTextStyle: .footnote, compatibleWith: .init(legibilityWeight: .bold))
        } else {
            let font = UIFont.preferredFont(forTextStyle: .footnote)
            let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) ?? font.fontDescriptor
            label.font = UIFont(descriptor: descriptor, size: 0)
        }
        if #available(iOS 13.0, *) {
            label.textColor = .label
        } else {
            label.textColor = .black
        }

        return label
    }

    func makeDateLabel() -> UILabel {
        let label = UILabel()

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .caption1)
        if #available(iOS 13.0, *) {
            label.textColor = .secondaryLabel
        } else {
            label.textColor = .gray
        }

        return label
    }

    func makeMessageTextView() -> UITextView {
        let textView = UITextView()

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .preferredFont(forTextStyle: .footnote)
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.textContainerInset = .zero
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.dataDetectorTypes = .all
        if #available(iOS 13.0, *) {
            textView.textColor = .label
        } else {
            textView.textColor = .black
        }

        return textView
    }
}

// MARK: - Date private extensions
fileprivate extension Date {
    var localizedRelativeDateTime: String {
        let currentDate = Date()
        guard currentDate.timeIntervalSinceNow - self.timeIntervalSinceNow > 60 else {
            return "Now"
        }

        if #available(iOS 13.0, *) {
            let formatter = RelativeDateTimeFormatter()

            formatter.dateTimeStyle = .named
            formatter.formattingContext = .listItem

            return formatter.localizedString(for: self, relativeTo: currentDate)
        } else {
            let formatter = DateComponentsFormatter()

            formatter.unitsStyle = .full
            formatter.allowedUnits = [.year, .month, .day, .hour, .minute, .second]
            formatter.zeroFormattingBehavior = .dropAll
            formatter.maximumUnitCount = 1

            return String(format: formatter.string(from: self, to: currentDate) ?? "", locale: .current)
        }
    }
}
