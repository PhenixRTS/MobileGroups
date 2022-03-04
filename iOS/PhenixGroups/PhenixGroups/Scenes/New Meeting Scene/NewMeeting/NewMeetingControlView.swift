//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Combine
import UIKit

class NewMeetingControlView: UIView {
    private lazy var displayNameTextField: UITextField = {
        var textField = UITextField.makePrimaryTextField(placeholder: "Display name")
        textField.delegate = self
        textField.setContentHuggingPriority(.required, for: .vertical)
        textField.setContentCompressionResistancePriority(.required, for: .vertical)
        return textField
    }()

    private lazy var displayNameCaptionLabel: UILabel = {
        let label = UILabel.makeTextFieldCaptionLabel(text: "Enter display name")
        label.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return label
    }()

    private lazy var newMeetingButton: UIButton = {
        let button = UIButton.makePrimaryButton(withTitle: "New meeting")
        button.setImage(.init(systemName: "plus"), for: .normal)
        button.addTarget(self, action: #selector(newMeetingTapped), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        button.sizeToFit()
        return button
    }()

    private lazy var joinMeetingButton: UIButton = {
        let button = UIButton.makePrimaryButton(withTitle: "Meeting code")
        button.setImage(.init(systemName: "keyboard"), for: .normal)
        button.addTarget(self, action: #selector(joinMeetingTapped), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        button.sizeToFit()
        return button
    }()

    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [newMeetingButton, joinMeetingButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        return stackView
    }()

    private var cancellables = Set<AnyCancellable>()
    private var isKeyboardVisible = false
    private var bottomConstraint: NSLayoutConstraint!

    var displayName: String {
        get { displayNameTextField.text ?? "" }
        set { displayNameTextField.text = newValue }
    }

    weak var delegate: NewMeetingControlViewDelegate?

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
        endEditing(true)
        bottomConstraint.constant = -16
    }

    // MARK: - Private methods

    private func setup() {
        setupUserInterfaceElements()
        subscribeToNotifications()
    }

    private func setupUserInterfaceElements() {
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

    private func subscribeToNotifications(notificationCenter: NotificationCenter = .default) {
        notificationCenter
            .publisher(for: UIResponder.keyboardWillHideNotification, object: nil)
            .sink { [weak self] notification in
                self?.adjustForKeyboard(notification: notification)
            }
            .store(in: &cancellables)

        notificationCenter
            .publisher(for: UIResponder.keyboardWillChangeFrameNotification, object: nil)
            .sink { [weak self] notification in
                self?.adjustForKeyboard(notification: notification)
            }
            .store(in: &cancellables)
    }

    @objc
    private func newMeetingTapped(_ sender: UIButton) {
        delegate?.newMeetingControlViewDidTapNewMeetingButton(self)
    }

    @objc
    private func joinMeetingTapped(_ sender: UIButton) {
        delegate?.newMeetingControlViewDidTapJoinMeetingButton(self)
    }

    @objc
    private func adjustForKeyboard(notification: Notification) {
        guard traitCollection.horizontalSizeClass == .compact && traitCollection.verticalSizeClass == .regular else {
            return
        }

        guard let userInfo = notification.userInfo else {
            return
        }

        guard let keyboardValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }

        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber else {
            return
        }

        let keyboardAnimation = duration.doubleValue

        switch (notification.name, isKeyboardVisible) {
        case (UIResponder.keyboardWillHideNotification, true):
            bottomConstraint.constant = -16
            isKeyboardVisible = false

        case (_, false):
            let keyboardScreenEndFrame = keyboardValue.cgRectValue
            let keyboardViewEndFrame = convert(keyboardScreenEndFrame, from: window)

            bottomConstraint.constant = -16 - (displayNameTextField.frame.maxY - keyboardViewEndFrame.minY) - 20
            isKeyboardVisible = true

        default:
            break
        }

        UIView.animate(withDuration: keyboardAnimation) {
            self.window?.layoutIfNeeded()
        }
    }

    // MARK: - UI Element Factory methods

    private func makeDisplayNameElements() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(displayNameCaptionLabel)
        view.addSubview(displayNameTextField)

        NSLayoutConstraint.activate([
            displayNameCaptionLabel.topAnchor.constraint(equalTo: view.topAnchor),
            displayNameCaptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            displayNameCaptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            displayNameTextField.topAnchor.constraint(equalTo: displayNameCaptionLabel.bottomAnchor, constant: 5),
            displayNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            displayNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            displayNameTextField.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        return view
    }

    private func makeMeetingButtons() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStackView)

        NSLayoutConstraint.activate([
            buttonStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            buttonStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0)
        ])

        return view
    }
}

// MARK: - UITextFieldDelegate
extension NewMeetingControlView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        delegate?.newMeetingControlView(self, didChangeDisplayName: textField.text ?? "")
        return true
    }
}
