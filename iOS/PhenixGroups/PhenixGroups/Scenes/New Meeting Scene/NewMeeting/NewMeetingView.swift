//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

class NewMeetingView: UIView {
    private static let maxHistoryHeight: CGFloat = 186

    private lazy var muteImageView: UIImageView = {
        let view = UIImageView.makeMuteImageView()
        return view
    }()

    private lazy var menuButton: UIButton = {
        let button = UIButton.makeMenuButton()
        button.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)
        return button
    }()

    private var buttonShadowGradient: CAGradientLayer!

    var cameraLayer: CALayer {
        cameraView.cameraLayer
    }

    weak var delegate: NewMeetingViewDelegate?

    @IBOutlet private var cameraView: CameraView!
    @IBOutlet private var controlView: NewMeetingControlView! {
        didSet { controlView.delegate = self }
    }
    @IBOutlet private var controlViewContainer: UIView!
    @IBOutlet private var historyViewContainer: UIView!
    @IBOutlet private var historyContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var buttonShadowView: UIView!
    @IBOutlet private var microphoneButton: ControlButton! {
        didSet { microphoneButton.configureAsMicrophoneButton() }
    }
    @IBOutlet private var cameraButton: ControlButton! {
        didSet { cameraButton.configureAsCameraButton() }
    }

    @IBAction
    private func microphoneButtonTapped(_ sender: ControlButton) {
        sender.controlState.toggle()
        delegate?.newMeetingView(self, didChangeMicrophoneState: sender.controlState == .on)
    }

    @IBAction
    private func cameraButtonTapped(_ sender: ControlButton) {
        sender.controlState.toggle()
        delegate?.newMeetingView(self, didChangeCameraState: sender.controlState == .on)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        buttonShadowGradient.frame = buttonShadowView.bounds
    }

    func configure(displayName: String) {
        layer.masksToBounds = true

        controlView.displayName = displayName
        cameraView.placeholderText = displayName

        historyContainerHeightConstraint.constant = Self.maxHistoryHeight

        controlViewContainer.layer.masksToBounds = true
        controlViewContainer.layer.cornerRadius = 10

        configureShadowView()

        addSubview(muteImageView)
        addSubview(menuButton)

        NSLayoutConstraint.activate([
            muteImageView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: -8),
            muteImageView.centerYAnchor.constraint(equalTo: microphoneButton.centerYAnchor),
            muteImageView.widthAnchor.constraint(equalToConstant: 44),
            muteImageView.heightAnchor.constraint(equalToConstant: 44),

            menuButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            menuButton.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: -8),
            menuButton.widthAnchor.constraint(equalToConstant: 44),
            menuButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Media control

    func setMicrophoneMuteIcon(visible: Bool) {
        muteImageView.isHidden = visible == false
    }

    func setMicrophoneControlButton(active: Bool) {
        setControl(microphoneButton, enabled: active)
    }

    func setCamera(visible: Bool) {
        cameraView.showCamera = visible
    }

    func setCamera(placeholder text: String) {
        cameraView.placeholderText = text
    }

    func setCameraControlButton(active: Bool) {
        setControl(cameraButton, enabled: active)
    }

    // MARK: - Other

    func setupHistoryView(_ view: UIView) {
        historyViewContainer.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: historyViewContainer.topAnchor),
            view.bottomAnchor.constraint(equalTo: historyViewContainer.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: historyViewContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: historyViewContainer.trailingAnchor)
        ])
    }

    // MARK: - Private methods

    private func configureShadowView() {
        buttonShadowGradient = CAGradientLayer()

        buttonShadowGradient.frame = buttonShadowView.bounds
        buttonShadowGradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.2).cgColor
        ]

        buttonShadowView.layer.insertSublayer(buttonShadowGradient, at: 0)
    }

    private func setControl(_ control: ControlButton, enabled: Bool) {
        control.controlState = enabled == true ? .on : .off
    }

    @objc
    private func menuButtonTapped() {
        delegate?.newMeetingViewDidTapMenuButton(self)
    }
}

// MARK: - MeetingHistoryViewDelegate
extension NewMeetingView: MeetingHistoryTableViewDelegate {
    func tableContentSizeDidChange(_ size: CGSize) {
        guard size.height <= Self.maxHistoryHeight else {
            return
        }

        historyContainerHeightConstraint.constant = size.height
    }
}

// MARK: - NewMeetingControlViewDelegate
extension NewMeetingView: NewMeetingControlViewDelegate {
    func newMeetingControlViewDidTapNewMeetingButton(_ view: NewMeetingControlView) {
        delegate?.newMeetingViewDidTapNewMeetingButton(self)
    }

    func newMeetingControlViewDidTapJoinMeetingButton(_ view: NewMeetingControlView) {
        delegate?.newMeetingViewDidTapJoinMeetingButton(self)
    }

    func newMeetingControlView(_ view: NewMeetingControlView, didChangeDisplayName displayName: String) {
        delegate?.newMeetingView(self, didChangeDisplayName: displayName)
    }
}
