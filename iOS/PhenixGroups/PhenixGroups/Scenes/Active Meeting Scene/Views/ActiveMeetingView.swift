//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class ActiveMeetingView: UIView {
    var leaveMeetingHandler: (() -> Void)?

    @IBOutlet private var buttonShadowView: UIView!
    @IBOutlet private var microphoneButton: ControlButton!
    @IBOutlet private var leaveMeetingButton: ControlButton!
    @IBOutlet private var cameraButton: ControlButton!

    @IBAction
    private func leaveMeetingTapped(_ sender: ControlButton) {
        leaveMeetingHandler?()
    }

    @IBAction
    private func microphoneButtonTapped(_ sender: ControlButton) {
        sender.controlState.toggle()
    }

    @IBAction
    private func cameraButtonTapped(_ sender: ControlButton) {
        sender.controlState.toggle()
    }

    func configure() {
        configureButtons()
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
}
