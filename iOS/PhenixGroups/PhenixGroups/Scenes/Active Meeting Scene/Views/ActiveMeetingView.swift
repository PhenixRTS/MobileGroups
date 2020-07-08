//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

class ActiveMeetingView: UIView {
    typealias ControlButtonHandler = (_ enabled: Bool) -> Void

    var notificationCenter: NotificationCenter = .default

    var leaveMeetingHandler: (() -> Void)?

    var microphoneHandler: ControlButtonHandler?
    var cameraHandler: ControlButtonHandler?

    @IBOutlet private var cameraView: CameraView!
    @IBOutlet private var buttonShadowView: UIView!
    @IBOutlet private var microphoneButton: ControlButton!
    @IBOutlet private var leaveMeetingButton: ControlButton!
    @IBOutlet private var cameraButton: ControlButton!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var containerViewBottomConstraint: NSLayoutConstraint!

    @IBAction
    private func leaveMeetingTapped(_ sender: ControlButton) {
        leaveMeetingHandler?()
    }

    @IBAction
    private func microphoneButtonTapped(_ sender: ControlButton) {
        sender.controlState.toggle()
        microphoneHandler?(sender.controlState == .on)
    }

    @IBAction
    private func cameraButtonTapped(_ sender: ControlButton) {
        sender.controlState.toggle()

        let enabled = sender.controlState == .on
        cameraHandler?(enabled)
    }

    func configure(displayName: String) {
        configureButtons()
        cameraView.placeholderText = displayName
        subscribeToNotifications()
    }

    func setMicrophoneControl(enabled: Bool) {
        setControl(microphoneButton, enabled: enabled)
    }

    func setCameraControl(enabled: Bool) {
        setControl(cameraButton, enabled: enabled)
    }

    func setCamera(enabled: Bool) {
        showCamera(enabled)
    }

    func setCamera(layer: VideoLayer?) {
        if let layer = layer {
            cameraView.setCameraLayer(layer)
        } else {
            cameraView.removeCameraLayer()
        }
    }

    func setCamera(placeholder text: String) {
        cameraView.placeholderText = text
    }

    func setPageView(_ pageView: UIView) {
        containerView.addSubview(pageView)

        pageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            pageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
}

private extension ActiveMeetingView {
    func configureButtons() {
        configureMicrophoneButton()
        configureCameraButton()
        configureLeaveMeetingButton()
    }

    func configureMicrophoneButton() {
        let borderColor: UIColor

        if #available(iOS 13.0, *) {
            borderColor = UIColor(named: "Button Border Color") ?? UIColor.systemBackground
        } else {
            borderColor = .white
        }

        microphoneButton.setImage(UIImage(named: "mic"), for: .on)
        microphoneButton.setImage(UIImage(named: "mic_off"), for: .off)

        microphoneButton.setBorderColor(borderColor, for: .on)
        microphoneButton.setBorderColor(.clear, for: .off)
        microphoneButton.setHighlightedBorderColor(borderColor, for: .on)
        microphoneButton.setHighlightedBorderColor(.clear, for: .off)

        microphoneButton.setBackgroundColor(.clear, for: .on)
        microphoneButton.setBackgroundColor(.systemRed, for: .off)
        microphoneButton.setHighlightedBackgroundColor(UIColor.white.withAlphaComponent(0.2), for: .on)
        microphoneButton.setHighlightedBackgroundColor(UIColor.systemRed.withAlphaComponent(0.2), for: .off)

        microphoneButton.refreshStateRepresentation()
    }

    func configureCameraButton() {
        let borderColor: UIColor

        if #available(iOS 13.0, *) {
            borderColor = UIColor(named: "Button Border Color") ?? UIColor.systemBackground
        } else {
            borderColor = .white
        }

        cameraButton.setImage(UIImage(named: "camera"), for: .on)
        cameraButton.setImage(UIImage(named: "camera_off"), for: .off)

        cameraButton.setBorderColor(borderColor, for: .on)
        cameraButton.setBorderColor(.clear, for: .off)
        cameraButton.setHighlightedBorderColor(borderColor, for: .on)
        cameraButton.setHighlightedBorderColor(.clear, for: .off)

        cameraButton.setBackgroundColor(.clear, for: .on)
        cameraButton.setBackgroundColor(.systemRed, for: .off)
        cameraButton.setHighlightedBackgroundColor(UIColor.white.withAlphaComponent(0.2), for: .on)
        cameraButton.setHighlightedBackgroundColor(UIColor.systemRed.withAlphaComponent(0.2), for: .off)

        cameraButton.refreshStateRepresentation()
    }

    func configureLeaveMeetingButton() {
        leaveMeetingButton.setImage(UIImage(named: "call_end"), for: .on)
        leaveMeetingButton.setImage(UIImage(named: "call_end"), for: .off)

        leaveMeetingButton.setBorderColor(.clear, for: .on)
        leaveMeetingButton.setBorderColor(.clear, for: .off)
        leaveMeetingButton.setHighlightedBorderColor(.clear, for: .on)
        leaveMeetingButton.setHighlightedBorderColor(.clear, for: .off)

        leaveMeetingButton.setBackgroundColor(.systemRed, for: .on)
        leaveMeetingButton.setBackgroundColor(.systemRed, for: .off)
        leaveMeetingButton.setHighlightedBackgroundColor(UIColor.systemRed.withAlphaComponent(0.2), for: .on)
        leaveMeetingButton.setHighlightedBackgroundColor(UIColor.systemRed.withAlphaComponent(0.2), for: .off)

        leaveMeetingButton.refreshStateRepresentation()
    }

    func setControl(_ control: ControlButton, enabled: Bool) {
        control.controlState = enabled == true ? .on : .off
    }

    func showCamera(_ show: Bool) {
        cameraView.showCamera = show
    }

    func subscribeToNotifications() {
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
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
            containerViewBottomConstraint.constant = 0
        } else {
            containerViewBottomConstraint.constant = keyboardViewEndFrame.height - safeAreaInsets.bottom
        }

        UIView.animate(withDuration: keyboardAnimation) {
            self.window?.layoutIfNeeded()
        }
    }
}

extension ActiveMeetingView: RoomMemberVideoObserver {
    func roomMemberVideoStateDidChange(_ member: RoomMember, enabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.showCamera(enabled)
        }
    }
}
