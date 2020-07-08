//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class ActiveMeetingChatView: UIView {
    private let textViewHeightInitialHeight: CGFloat = 50

    var notificationCenter: NotificationCenter = .default
    var tableView: UITableView!

    private var textView: PlaceholderTextView!
    private var textViewHeightConstraint: NSLayoutConstraint!
    private var sendButton: UIButton!

    var sendMessageHandler: ActiveMeetingChatViewController.SendMessageHandler?


    override init(frame: CGRect) {
         super.init(frame: frame)
         setup()
    }

    required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
         setup()
    }

    func resizeTextView() {
        let contentSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .infinity))
        textViewHeightConstraint.constant = contentSize.height
        textView.isScrollEnabled = contentSize.height > 100
    }

    @objc
    func sendButtonTapped(_ sender: Any?) {
        sendButton.isEnabled = false
        sendMessageHandler?(textView.text)
        textView.text = ""
        resizeTextView()
    }

    func reloadData() {
        tableView.reloadData()
        tableView.scrollToBottom(animated: true)
    }
}

private extension ActiveMeetingChatView {
    func setup() {
        tableView = makeTableView()
        textView = makeTextView()
        textView.delegate = self
        sendButton = makeSendButton()

        let divider = makeDivider()

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

        tableView.scrollToBottom(animated: false)

        subscribeToNotifications()
    }

    func subscribeToNotifications() {
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    @objc
    func adjustForKeyboard(notification: Notification) {
        tableView.scrollToBottom(animated: true)
    }
}

private extension ActiveMeetingChatView {
    func makeTableView() -> UITableView {
        let view = UITableView()

        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }

    func makeTextView() -> PlaceholderTextView {
        let view = PlaceholderTextView()

        view.translatesAutoresizingMaskIntoConstraints = false
        view.isScrollEnabled = false
        view.font = .preferredFont(forTextStyle: .footnote)
        view.adjustsFontForContentSizeCategory = true
        view.placeholder = "Message"
        view.setPlaceholder(visible: true)

        return view
    }

    func makeDivider() -> UIView {
        let view = UIView(frame: .zero)

        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemGray
        } else {
            view.backgroundColor = .gray
        }

        return view
    }

    func makeSendButton() -> UIButton {
        let image = UIImage(named: "send")
        let button = UIButton(type: .system)

        button.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            button.tintColor = .label
        } else {
            button.tintColor = .black
        }
        button.setImage(image, for: .normal)
        button.isEnabled = false
        button.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)

        return button
    }
}

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

// MARK: - UITableView private extensions
fileprivate extension UITableView {
    var isBottomRowBelow: Bool {
        contentOffset.y < (contentSize.height - frame.size.height)
    }

    func scrollToBottom(animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
            guard let rowCount = self?.numberOfRows(inSection: 0), rowCount > 0 else { return }
            let lastRowIndex = rowCount < 2 ? 0 : rowCount - 1
            let indexPath = IndexPath(row: lastRowIndex, section: 0)
            self?.scrollToRow(at: indexPath, at: .bottom, animated: animated)
        }
    }
}
