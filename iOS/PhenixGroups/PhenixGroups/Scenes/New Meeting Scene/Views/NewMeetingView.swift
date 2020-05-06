//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class NewMeetingView: UIView {
    @IBOutlet private var controlView: NewMeetingControlView!
    @IBOutlet private var controlViewContainer: UIView!
    @IBOutlet private var historyViewContainer: UIView!
    @IBOutlet private var historyContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var buttonShadowView: UIView!
    @IBOutlet private var microphoneButton: MicrophoneControlButton!
    @IBOutlet private var cameraButton: CameraControlButton!

    @IBAction
    private func microphoneButtonTapped(_ sender: MicrophoneControlButton) {
        sender.controlState.toggle()
    }

    @IBAction
    private func cameraButtonTapped(_ sender: CameraControlButton) {
        sender.controlState.toggle()
    }

    func configure(displayName: String) {
        controlViewContainer.layer.masksToBounds = true
        controlViewContainer.layer.cornerRadius = 10

        controlView.displayName = displayName
        configureShadowView()
    }

    func setNewMeetingHandler(_ completion: @escaping NewMeetingControlView.ButtonTapHandler) {
        controlView.newMeetingTapHandler = completion
    }

    func setJoinMeetingHandler(_ completion: @escaping NewMeetingControlView.ButtonTapHandler) {
        controlView.joinMeetingTapHandler = completion
    }

    func setDisplayNameDelegate(_ delegate: DisplayNameDelegate) {
        controlView.delegate = delegate
    }

    func setupHistoryView(_ view: UIView) {
        historyViewContainer.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        // swiftlint:disable multiline_arguments_brackets
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: historyViewContainer.topAnchor),
            view.bottomAnchor.constraint(equalTo: historyViewContainer.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: historyViewContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: historyViewContainer.trailingAnchor)
        ])
    }
}

private extension NewMeetingView {
    func configureShadowView() {
        let gradient = CAGradientLayer()

        gradient.frame = buttonShadowView.bounds
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.2).cgColor
        ]

        buttonShadowView.layer.insertSublayer(gradient, at: 0)
    }
}

extension NewMeetingView: MeetingHistoryDelegate {
    func tableContentSizeDidChange(_ size: CGSize) {
        guard size.height < 150 else { return }
        historyContainerHeightConstraint.constant = size.height

        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }
}
