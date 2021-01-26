//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

class NewMeetingView: UIView {
    typealias ControlButtonHandler = (_ enabled: Bool) -> Void

    static let maxHistoryHeight: CGFloat = 186

    var displayName: String {
        get { controlView.displayName }
        set { cameraView.placeholderText = newValue }
    }

    var microphoneHandler: ControlButtonHandler?
    var cameraHandler: ControlButtonHandler?
    var openMenuHandler: (() -> Void)?
    var cameraViewMultipleTapHandler: (() -> Void)?

    private var muteImage: UIImageView!
    private var buttonShadowGradient: CAGradientLayer!
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

        let enabled = sender.controlState == .on
        microphoneHandler?(enabled)

        showMuteIcon(enabled == false)
    }

    @IBAction
    private func cameraButtonTapped(_ sender: ControlButton) {
        sender.controlState.toggle()

        let enabled = sender.controlState == .on
        cameraHandler?(enabled)

        showCamera(enabled)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        buttonShadowGradient.frame = buttonShadowView.bounds
    }

    func configure(displayName: String) {
        layer.masksToBounds = true

        historyContainerHeightConstraint.constant = Self.maxHistoryHeight

        controlViewContainer.layer.masksToBounds = true
        controlViewContainer.layer.cornerRadius = 10

        controlView.displayName = displayName
        configureShadowView()
        configureButtons()

        cameraView.placeholderText = displayName
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cameraViewTappedMultipleTimes))
        tapGesture.numberOfTapsRequired = 5
        cameraView.addGestureRecognizer(tapGesture)

        muteImage = UIImageView.makeMuteImageView()

        let menu = UIButton.makeMenuButton()
        menu.addTarget(self, action: #selector(openMenu), for: .touchUpInside)

        addSubview(muteImage)
        addSubview(menu)

        NSLayoutConstraint.activate([
            muteImage.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: -8),
            muteImage.centerYAnchor.constraint(equalTo: microphoneButton.centerYAnchor),
            muteImage.widthAnchor.constraint(equalToConstant: 44),
            muteImage.heightAnchor.constraint(equalToConstant: 44),

            menu.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            menu.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: -8),
            menu.widthAnchor.constraint(equalToConstant: 44),
            menu.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    func setNewMeetingHandler(_ completion: @escaping NewMeetingControlView.ButtonTapHandler) {
        controlView.newMeetingTapHandler = completion
    }

    func setJoinMeetingHandler(_ completion: @escaping NewMeetingControlView.ButtonTapHandler) {
        controlView.joinMeetingTapHandler = completion
    }

    func setMicrophone(enabled: Bool) {
        setControl(microphoneButton, enabled: enabled)
        showMuteIcon(enabled == false)
    }

    func setCamera(enabled: Bool) {
        setControl(cameraButton, enabled: enabled)
        showCamera(enabled)
    }

    func setDisplayNameDelegate(_ delegate: DisplayNameDelegate) {
        controlView.delegate = delegate
    }

    func setCamera(layer: VideoLayer) {
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
        buttonShadowGradient = CAGradientLayer()

        buttonShadowGradient.frame = buttonShadowView.bounds
        buttonShadowGradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.2).cgColor
        ]

        buttonShadowView.layer.insertSublayer(buttonShadowGradient, at: 0)
    }

    func configureButtons() {
        let borderColor: UIColor

        if #available(iOS 13.0, *) {
            borderColor = UIColor(named: "button_border") ?? UIColor.systemBackground
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

    func setControl(_ control: ControlButton, enabled: Bool) {
        control.controlState = enabled == true ? .on : .off
    }

    func showMuteIcon(_ show: Bool) {
        muteImage.isHidden = show == false
    }

    func showCamera(_ show: Bool) {
        cameraView.showCamera = show
    }

    @objc
    func openMenu() {
        openMenuHandler?()
    }

    @objc
    func cameraViewTappedMultipleTimes() {
        cameraViewMultipleTapHandler?()
    }
}

// MARK: - MeetingHistoryViewDelegate
extension NewMeetingView: MeetingHistoryViewDelegate {
    func tableContentSizeDidChange(_ size: CGSize) {
        guard size.height <= Self.maxHistoryHeight else { return }

        historyContainerHeightConstraint.constant = size.height

        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }
}
