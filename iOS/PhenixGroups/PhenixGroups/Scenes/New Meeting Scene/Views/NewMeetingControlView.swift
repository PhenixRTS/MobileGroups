//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class NewMeetingControlView: UIView {
    typealias ButtonTapHandler = (_ displayName: String) -> Void

    private var displayNameLabel: UILabel!
    private var displayNameTextField: UITextField!
    private var newMeetingButton: UIButton!
    private var joinMeetingButton: UIButton!
    private var bottomConstraint: NSLayoutConstraint!

    var displayName: String {
        get { displayNameTextField.text ?? "" }
        set { displayNameTextField.text = newValue }
    }

    weak var delegate: DisplayNameDelegate?

    var newMeetingTapHandler: ButtonTapHandler?
    var joinMeetingTapHandler: ButtonTapHandler?

    var notificationCenter: NotificationCenter = .default

    override init(frame: CGRect) {
         super.init(frame: frame)
         commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
         commonInit()
    }

    @objc
    func newMeetingTapped(_ sender: UIButton) {
        newMeetingTapHandler?(displayName)
    }

    @objc
    func joinMeetingTapped(_ sender: UIButton) {
        joinMeetingTapHandler?(displayName)
    }

    @objc
    func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        guard let keyboardAnimationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber else {
            return
        }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardAnimation = keyboardAnimationDuration.doubleValue
        let keyboardViewEndFrame = convert(keyboardScreenEndFrame, from: window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            bottomConstraint.constant = -16
        } else {
            bottomConstraint.constant = -(keyboardViewEndFrame.height - (frame.height - displayNameTextField.frame.maxY - 10))
        }

        UIView.animate(withDuration: keyboardAnimation) {
            self.window?.layoutIfNeeded()
        }
    }

    deinit {
        notificationCenter.removeObserver(self)
    }
}

private extension NewMeetingControlView {
    func commonInit() {
        setupUserInterfaceElements()
        subscribeToNotifications()
    }

    func setupUserInterfaceElements() {
        // swiftlint:disable multiline_arguments_brackets
        let stack = UIStackView(arrangedSubviews: [
            makeDisplayNameElements(),
            makeMeetingButtons()
        ])

        addSubview(stack)

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 10

        bottomConstraint = stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)

        // swiftlint:disable multiline_arguments_brackets
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            bottomConstraint
        ])
    }

    func subscribeToNotifications() {
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    func makeDisplayNameElements() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        // Display name label
        displayNameLabel = UILabel.displayNameLabel
        view.addSubview(displayNameLabel)

        // swiftlint:disable multiline_arguments_brackets
        NSLayoutConstraint.activate([
            displayNameLabel.topAnchor.constraint(equalTo: view.topAnchor),
            displayNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            displayNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Display name text field
        displayNameTextField = UITextField.displayNameTextField
        displayNameTextField.delegate = self
        view.addSubview(displayNameTextField)

        // swiftlint:disable multiline_arguments_brackets
        NSLayoutConstraint.activate([
            displayNameTextField.topAnchor.constraint(equalTo: displayNameLabel.bottomAnchor, constant: 5),
            displayNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            displayNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            displayNameTextField.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        return view
    }

    func makeMeetingButtons() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        newMeetingButton = .meetingButton(title: "NEW MEETING")
        newMeetingButton.addTarget(self, action: #selector(newMeetingTapped), for: .touchUpInside)

        joinMeetingButton = .meetingButton(title: "JOIN MEETING")
        joinMeetingButton.addTarget(self, action: #selector(joinMeetingTapped), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [
            newMeetingButton,
            joinMeetingButton
        ])

        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.spacing = 10
        buttonStack.axis = .horizontal
        buttonStack.alignment = .center
        view.addSubview(buttonStack)

        // swiftlint:disable multiline_arguments_brackets
        NSLayoutConstraint.activate([
            newMeetingButton.widthAnchor.constraint(equalTo: joinMeetingButton.widthAnchor),
            buttonStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            buttonStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0)
        ])

        return view
    }
}

extension NewMeetingControlView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        delegate?.saveDisplayName(textField.text ?? "")
        return true
    }
}
