//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class JoinMeetingView: UIView {
    typealias JoinHandler = (String) -> Void
    typealias CloseHandler = () -> Void

    private var closeButton: UIButton!
    private var joinButton: UIButton!
    private var meetingCodeTextField: UITextField!

    var joinMeetingHandler: JoinHandler?
    var closeHandler: CloseHandler?

    var meetingCode: String {
        meetingCodeTextField.text ?? ""
    }

    override init(frame: CGRect) {
         super.init(frame: frame)
         commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
         commonInit()
    }

    @objc
    func closeButtonTapped(_ sender: Any) {
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
}

private extension JoinMeetingView {
    func commonInit() {
        makeCloseButton()
        setupUserInterfaceElements()
    }

    func makeCloseButton() {
        let button = UIButton(type: .system)
        closeButton = button
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor(named: "Button Inverted Color")
        button.setImage(UIImage(named: "close_button"), for: .normal)
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            button.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 8),
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    func setupUserInterfaceElements() {
        let stack = UIStackView(arrangedSubviews: [
            makeTextField(),
            makeJoinButton()
        ])

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

    func makeTextField() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        // Display name label
        let label = UILabel.textFieldCaptionLabel("Enter a meeting code")
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let textField = UITextField.mainTextField(placeholder: "Meeting code")
        meetingCodeTextField = textField
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        view.addSubview(textField)
        textField.becomeFirstResponder()

        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 5),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textField.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        return view
    }

    func makeJoinButton() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton.mainButton(title: "Join meeting")
        joinButton = button
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        button.addTarget(self, action: #selector(joinButtonTapped), for: .touchUpInside)
        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.topAnchor),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            button.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        return view
    }
}

extension JoinMeetingView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
