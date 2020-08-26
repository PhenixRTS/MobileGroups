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
    private var buttonStack: UIStackView!

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
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
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
        guard traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular else { return }
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        guard let keyboardAnimationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber else { return }

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
    func setup() {
        setupUserInterfaceElements()
        subscribeToNotifications()
    }

    func setupUserInterfaceElements() {
        let displayNameView = makeDisplayNameElements()
        let buttonsView = makeMeetingButtons()

        addSubview(displayNameView)
        addSubview(buttonsView)

        bottomConstraint = buttonsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)

        NSLayoutConstraint.activate([
            displayNameView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            displayNameView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            displayNameView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            buttonsView.topAnchor.constraint(equalTo: displayNameView.bottomAnchor, constant: 20),
            buttonsView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            buttonsView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            bottomConstraint
        ])
    }

    func subscribeToNotifications() {
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
}

// MARK: - UI Element Factory methods
private extension NewMeetingControlView {
    func makeDisplayNameElements() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        // Display name label
        let label = UILabel.makeTextFieldCaptionLabel(text: "Enter display name")
        label.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        // Display name text field
        displayNameTextField = UITextField.makePrimaryTextField(placeholder: "Display name")
        displayNameTextField.delegate = self
        displayNameTextField.setContentHuggingPriority(.required, for: .vertical)
        displayNameTextField.setContentCompressionResistancePriority(.required, for: .vertical)

        view.addSubview(label)
        view.addSubview(displayNameTextField)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor),

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

        newMeetingButton = UIButton.makePrimaryButton(withTitle: "New meeting")
        newMeetingButton.setImage(UIImage(named: "add"), for: .normal)
        newMeetingButton.addTarget(self, action: #selector(newMeetingTapped), for: .touchUpInside)
        newMeetingButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
        newMeetingButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: 0)
        newMeetingButton.sizeToFit()

        joinMeetingButton = UIButton.makePrimaryButton(withTitle: "Meeting code")
        joinMeetingButton.setImage(UIImage(named: "keyboard"), for: .normal)
        joinMeetingButton.addTarget(self, action: #selector(joinMeetingTapped), for: .touchUpInside)
        joinMeetingButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: spacing)
        joinMeetingButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing, bottom: 0, right: 0)
        joinMeetingButton.sizeToFit()

        buttonStack = UIStackView(arrangedSubviews: [
            newMeetingButton,
            joinMeetingButton
        ])

        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.spacing = 10
        buttonStack.axis = .horizontal
        buttonStack.alignment = .center
        buttonStack.distribution = .fillProportionally

        view.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            buttonStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            buttonStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0)
        ])

        return view
    }
}

// MARK: - UITextFieldDelegate
extension NewMeetingControlView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        delegate?.saveDisplayName(textField.text ?? "")
        return true
    }
}
