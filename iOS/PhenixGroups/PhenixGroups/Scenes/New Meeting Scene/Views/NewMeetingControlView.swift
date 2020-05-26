//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class NewMeetingControlView: UIView {
    typealias ButtonTapHandler = (_ displayName: String) -> Void

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
            bottomConstraint.constant = -16 - (displayNameTextField.frame.maxY - keyboardViewEndFrame.minY) - 20
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
        let stack = UIStackView(arrangedSubviews: [
            makeDisplayNameElements(),
            makeMeetingButtons()
        ])

        addSubview(stack)

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 20

        bottomConstraint = stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)

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
        let label = UILabel.textFieldCaptionLabel("Enter display name")
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Display name text field
        displayNameTextField = UITextField.mainTextField(placeholder: "Display name")
        displayNameTextField.delegate = self
        view.addSubview(displayNameTextField)

        NSLayoutConstraint.activate([
            displayNameTextField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 5),
            displayNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            displayNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            displayNameTextField.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        return view
    }

    func makeMeetingButtons() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        let spacing: CGFloat = 10 // the amount of spacing to appear between image and title

        newMeetingButton = UIButton.mainButton(title: "New meeting")
        newMeetingButton.setImage(UIImage(named: "add"), for: .normal)
        newMeetingButton.addTarget(self, action: #selector(newMeetingTapped), for: .touchUpInside)
        newMeetingButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
        newMeetingButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: 0)

        joinMeetingButton = UIButton.mainButton(title: "Meeting code")
        joinMeetingButton.setImage(UIImage(named: "keyboard"), for: .normal)
        joinMeetingButton.addTarget(self, action: #selector(joinMeetingTapped), for: .touchUpInside)
        joinMeetingButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
        joinMeetingButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: 0)

        let buttonStack = UIStackView(arrangedSubviews: [
            newMeetingButton,
            joinMeetingButton
        ])

        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.spacing = 10
        buttonStack.axis = .horizontal
        buttonStack.alignment = .center
        view.addSubview(buttonStack)

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
