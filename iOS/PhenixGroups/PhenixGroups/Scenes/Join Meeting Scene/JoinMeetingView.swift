//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class JoinMeetingView: UIView {
    typealias JoinHandler = (String) -> Void
    typealias CloseHandler = () -> Void

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .label
        button.setImage(.init(systemName: "x.circle"), for: .normal)
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var joinButton: UIButton = {
        let button = UIButton.makePrimaryButton(withTitle: "Join meeting")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        button.addTarget(self, action: #selector(joinButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var meetingCodeCaptionLabel: UILabel = {
        let label = UILabel.makeTextFieldCaptionLabel(text: "Enter a meeting code")
        return label
    }()

    private lazy var meetingCodeTextField: UITextField = {
        let textField = UITextField.makePrimaryTextField(placeholder: "Meeting code")
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        return textField
    }()

    var joinMeetingHandler: JoinHandler?
    var closeHandler: CloseHandler?

    var meetingCode: String {
        meetingCodeTextField.text?.lowercased() ?? ""
    }

    override init(frame: CGRect) {
         super.init(frame: frame)
         setup()
    }

    required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
         setup()
    }

    @objc
    func closeButtonTapped(_ sender: Any) {
        endEditing(true)
        closeHandler?()
    }

    @objc
    func joinButtonTapped(_ sender: Any) {
        guard let code = meetingCodeTextField.text else {
            return
        }

        guard code.isEmpty == false else {
            return
        }

        meetingCodeTextField.resignFirstResponder()
        joinMeetingHandler?(code)
    }

    @objc
    func textFieldDidChange(_ sender: UITextField) {
        joinButton.isEnabled = sender.text?.isEmpty == false
    }

    // MARK: - Private methods

    private func setup() {
        addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 8),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        setupUserInterfaceElements()
        meetingCodeTextField.becomeFirstResponder()
    }

    private func setupUserInterfaceElements() {
        let stack = UIStackView(arrangedSubviews: [makeTextFieldContainerView(), makeJoinButtonContainerView()])
        addSubview(stack)

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 10

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 30),
            stack.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16)
        ])
    }

    // MARK: - UI Element Factory methods

    private func makeTextFieldContainerView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(meetingCodeCaptionLabel)
        view.addSubview(meetingCodeTextField)

        NSLayoutConstraint.activate([
            meetingCodeCaptionLabel.topAnchor.constraint(equalTo: view.topAnchor),
            meetingCodeCaptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            meetingCodeCaptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            meetingCodeTextField.topAnchor.constraint(equalTo: meetingCodeCaptionLabel.bottomAnchor, constant: 5),
            meetingCodeTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            meetingCodeTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            meetingCodeTextField.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        return view
    }

    private func makeJoinButtonContainerView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(joinButton)

        NSLayoutConstraint.activate([
            joinButton.topAnchor.constraint(equalTo: view.topAnchor),
            joinButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            joinButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            joinButton.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        return view
    }
}

// MARK: - UITextFieldDelegate
extension JoinMeetingView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
