//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class NewMeetingView: UIView {
    typealias ControlButtonHandler = (_ enabled: Bool) -> Void

    static let maxHistoryHeight: CGFloat = 186

    var displayName: String {
        get { controlView.displayName }
        set { cameraPlaceholderView.text = newValue }
    }

    var microphoneHandler: ControlButtonHandler?
    var cameraHandler: ControlButtonHandler?

    private var cameraPlaceholderView: CameraPlaceholderView!
    @IBOutlet private var cameraView: CameraView!
    @IBOutlet private var controlView: NewMeetingControlView!
    @IBOutlet private var controlViewContainer: UIView!
    @IBOutlet private var historyViewContainer: UIView!
    @IBOutlet private var historyContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var buttonShadowView: UIView!
    @IBOutlet private var microphoneButton: ControlButton!
    @IBOutlet private var cameraButton: ControlButton!

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

        showCamera(enabled)
    }

    func configure(displayName: String) {
        layer.masksToBounds = true

        historyContainerHeightConstraint.constant = Self.maxHistoryHeight

        controlViewContainer.layer.masksToBounds = true
        controlViewContainer.layer.cornerRadius = 10

        controlView.displayName = displayName
        configureShadowView()
        configureButtons()

        setupCameraPlaceholderView(text: displayName)
    }

    func setNewMeetingHandler(_ completion: @escaping NewMeetingControlView.ButtonTapHandler) {
        controlView.newMeetingTapHandler = completion
    }

    func setJoinMeetingHandler(_ completion: @escaping NewMeetingControlView.ButtonTapHandler) {
        controlView.joinMeetingTapHandler = completion
    }

    func setMicrophone(enabled: Bool) {
        setControl(microphoneButton, enabled: enabled)
    }

    func setCamera(enabled: Bool) {
        setControl(cameraButton, enabled: enabled)
        showCamera(enabled)
    }

    func setDisplayNameDelegate(_ delegate: DisplayNameDelegate) {
        controlView.delegate = delegate
    }

    func setCameraLayer(_ layer: CALayer) {
        cameraView.setCameraLayer(layer)
    }

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

    func configureButtons() {
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

    func setupCameraPlaceholderView(text: String) {
        let view = CameraPlaceholderView()
        cameraPlaceholderView = view
        view.translatesAutoresizingMaskIntoConstraints = false
        view.text = text

        insertSubview(view, aboveSubview: cameraView)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: controlViewContainer.topAnchor, constant: 30)
        ])
    }

    func setControl(_ control: ControlButton, enabled: Bool) {
        control.controlState = enabled == true ? .on : .off
    }

    func showCamera(_ show: Bool) {
        cameraView.isHidden = !show
        cameraPlaceholderView.isHidden = show
    }
}

extension NewMeetingView: MeetingHistoryViewDelegate {
    func tableContentSizeDidChange(_ size: CGSize) {
        guard size.height <= Self.maxHistoryHeight else { return }

        historyContainerHeightConstraint.constant = size.height

        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }
}
