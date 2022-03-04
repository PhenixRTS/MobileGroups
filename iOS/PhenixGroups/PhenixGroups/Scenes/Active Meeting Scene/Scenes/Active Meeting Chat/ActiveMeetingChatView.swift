//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Combine
import UIKit

class ActiveMeetingChatView: UIView {
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.estimatedRowHeight = 20
        tableView.rowHeight = UITableView.automaticDimension
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.tableFooterView = UIView()
        return tableView
    }()

    private lazy var textView: PlaceholderTextView = {
        let view = PlaceholderTextView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.font = .preferredFont(forTextStyle: .footnote)
        view.delegate = self
        view.placeholder = "Message"
        view.isScrollEnabled = false
        view.adjustsFontForContentSizeCategory = true
        view.setPlaceholder(visible: true)
        return view
    }()

    private lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .label
        button.setImage(.init(systemName: "paperplane"), for: .normal)
        button.isEnabled = false
        button.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        return button
    }()

    private let textViewHeightInitialHeight: CGFloat = 50

    private var textViewHeightConstraint: NSLayoutConstraint!
    private var cancellable: AnyCancellable?

    weak var delegate: ActiveMeetingChatViewDelegate?

    override init(frame: CGRect) {
         super.init(frame: frame)
         setup()
    }

    required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
         setup()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        scrollTableViewToBottom(tableView, animated: false)
    }

    func resizeTextView() {
        let contentSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .infinity))
        textViewHeightConstraint.constant = contentSize.height
        textView.isScrollEnabled = contentSize.height > 100
    }

    @objc
    func sendButtonTapped(_ sender: Any?) {
        sendButton.isEnabled = false
        delegate?.activeMeetingChatView(self, didTapSendMessageButtonWithText: textView.text)

        textView.text = ""
        resizeTextView()
    }

    func scrollToBottom() {
        scrollTableViewToBottom(tableView, animated: true)
    }

    // MARK: - Private methods

    private func setup() {
        let divider = UIView(frame: .zero)
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = .systemGray

        addSubview(tableView)
        addSubview(textView)
        addSubview(divider)
        addSubview(sendButton)

        textViewHeightConstraint = textView.heightAnchor.constraint(equalToConstant: 20)
        textViewHeightConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),

            divider.topAnchor.constraint(equalTo: tableView.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),

            textView.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
            textView.heightAnchor.constraint(lessThanOrEqualToConstant: 100),
            textViewHeightConstraint,

            sendButton.topAnchor.constraint(greaterThanOrEqualTo: divider.bottomAnchor),
            sendButton.leadingAnchor.constraint(equalTo: textView.trailingAnchor, constant: 10),
            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            sendButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 44),
            sendButton.heightAnchor.constraint(equalToConstant: 44),
            sendButton.centerYAnchor.constraint(equalTo: textView.centerYAnchor)
        ])

        subscribeToKeyboardNotifications()
        scrollTableViewToBottom(tableView, animated: false)
    }

    private func subscribeToKeyboardNotifications(notificationCenter: NotificationCenter = .default) {
        cancellable = notificationCenter
            .publisher(for: UIResponder.keyboardWillShowNotification, object: nil)
            .sink { [weak self] notification in
                self?.adjustForKeyboard(notification: notification)
            }
    }

    private func adjustForKeyboard(notification: Notification) {
        scrollTableViewToBottom(tableView, animated: true)
    }

    private func scrollTableViewToBottom(_ tableView: UITableView, animated: Bool) {
        guard let numberOfRows = delegate?.totalNumberOfRows(), numberOfRows > 0 else {
            return
        }

        let lastRowIndex = numberOfRows < 2 ? 0 : numberOfRows - 1
        let indexPath = IndexPath(row: lastRowIndex, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
}

// MARK: - UITextViewDelegate
extension ActiveMeetingChatView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        sendButton.isEnabled = textView.text.isEmpty == false
        resizeTextView()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let placeholderTextView = textView as? PlaceholderTextView else {
            return true
        }

        let currentText: String = textView.text
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)

        placeholderTextView.setPlaceholder(visible: updatedText.isEmpty)

        return true
    }
}
