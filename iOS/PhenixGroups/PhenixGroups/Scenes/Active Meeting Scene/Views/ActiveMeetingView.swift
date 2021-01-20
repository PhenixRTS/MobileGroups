//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

class ActiveMeetingView: UIView {
    typealias ControlButtonHandler = (_ enabled: Bool) -> Void

    var notificationCenter: NotificationCenter = .default
    var leaveMeetingHandler: (() -> Void)?
    var microphoneHandler: ControlButtonHandler?
    var cameraHandler: ControlButtonHandler?
    var openMenuHandler: (() -> Void)?
    var scrollToSection: ((Int) -> Void)?
    var cameraViewMultipleTapHandler: (() -> Void)?

    private var isContainerVisibleInLandscape: Bool = false {
        didSet {
            showContainerInLandscape(isContainerVisibleInLandscape)
        }
    }

    private var isControlsVisible: Bool = true {
        didSet {
            showControls(isControlsVisible)
        }
    }

    private var muteImage: UIImageView!
    private var menuButton: UIButton!
    private var menuButtonConstraintToTopControlButtons: NSLayoutConstraint!
    private var topControlButtonStackView: UIStackView!
    @IBOutlet private var cameraView: CameraView!
    @IBOutlet private var buttonShadowView: UIView!
    @IBOutlet private var controlButtonStackView: UIStackView!
    @IBOutlet private var microphoneButton: ControlButton!
    @IBOutlet private var leaveMeetingButton: ControlButton!
    @IBOutlet private var cameraButton: ControlButton!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var containerViewBottomConstraint: NSLayoutConstraint!
    // Constraint positions container view leading anchor to be equal with view trailing anchor. It pushes the container view outside of the visible view part.
    @IBOutlet private var containerViewLandscapeLeadingSuperviewConstraint: NSLayoutConstraint!

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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        topControlButtonStackView.isHidden = traitCollection.verticalSizeClass != .compact
        isContainerVisibleInLandscape = false
    }

    func configure(displayName: String) {
        configureButtons()
        cameraView.placeholderText = displayName

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cameraViewTapped))
        cameraView.addGestureRecognizer(tapGesture)
        let multiTapGesture = UITapGestureRecognizer(target: self, action: #selector(cameraViewTappedMultipleTimes))
        multiTapGesture.numberOfTapsRequired = 5
        cameraView.addGestureRecognizer(multiTapGesture)

        muteImage = UIImageView.makeMuteImageView()

        menuButton = UIButton.makeMenuButton()
        menuButton.addTarget(self, action: #selector(openMenu), for: .touchUpInside)

        topControlButtonStackView = UIStackView()
        topControlButtonStackView.translatesAutoresizingMaskIntoConstraints = false
        topControlButtonStackView.axis = .horizontal
        topControlButtonStackView.spacing = 16
        topControlButtonStackView.isHidden = traitCollection.verticalSizeClass != .compact

        addSubview(muteImage)
        addSubview(menuButton)
        insertSubview(topControlButtonStackView, aboveSubview: cameraView)

        NSLayoutConstraint.activate([
            muteImage.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: -8),
            muteImage.centerYAnchor.constraint(equalTo: microphoneButton.centerYAnchor),
            muteImage.widthAnchor.constraint(equalToConstant: 44),
            muteImage.heightAnchor.constraint(equalToConstant: 44),

            topControlButtonStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            topControlButtonStackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),

            menuButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            menuButton.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: -8),
            menuButton.widthAnchor.constraint(equalToConstant: 44),
            menuButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        subscribeToNotifications()
    }

    func setMicrophoneControl(enabled: Bool) {
        setControl(microphoneButton, enabled: enabled)
    }

    func setMicrophone(enabled: Bool) {
        showMuteIcon(enabled == false)
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
        pageView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(pageView)

        NSLayoutConstraint.activate([
            pageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            pageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    @objc
    func cameraViewTapped(_ sender: Any) {
        endEditing(true)
        if traitCollection.verticalSizeClass == .compact && isContainerVisibleInLandscape == true {
            isContainerVisibleInLandscape = false
        } else {
            isControlsVisible.toggle()
        }
    }

    @objc
    func cameraViewTappedMultipleTimes() {
        cameraViewMultipleTapHandler?()
    }

    func addTopControl(for page: PageContainerMember) {
        let button = makeTopControlButton(icon: page.pageIcon, title: page.title ?? "")
        button.addTarget(self, action: #selector(topControlButtonTapped), for: .touchUpInside)
        button.tag = topControlButtonStackView.arrangedSubviews.count

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])

        topControlButtonStackView.addArrangedSubview(button)
    }

    func refreshLandscapePosition() {
        showContainerInLandscape(isContainerVisibleInLandscape, withAnimation: false)
    }
}

private extension ActiveMeetingView {
    func configureButtons() {
        configureMicrophoneButton()
        configureCameraButton()
        configureLeaveMeetingButton()
    }

    func configureMicrophoneButton() {
        let borderColor: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor(named: "button_border") ?? .systemBackground
            } else {
                return .white
            }
        }()

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
        let borderColor: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor(named: "button_border") ?? UIColor.systemBackground
            } else {
                return .white
            }
        }()

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

    func showMuteIcon(_ show: Bool) {
        muteImage.isHidden = show == false
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
        guard let keyboardAnimationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber else { return }

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

    @objc
    func openMenu() {
        openMenuHandler?()
    }

    func showContainerInLandscape(_ show: Bool, withAnimation: Bool = true) {
        guard traitCollection.verticalSizeClass == .compact else {
            return
        }

        // By activating `containerViewLandscapeLeadingSuperviewConstraint` control view will hide, and by deactivating - show.

        if show {
            containerViewLandscapeLeadingSuperviewConstraint.isActive = false
        } else {
            containerViewLandscapeLeadingSuperviewConstraint.isActive = true
        }

        if withAnimation {
            UIView.animate(withDuration: 0.25) {
                self.layoutIfNeeded()
            }
        } else {
            layoutIfNeeded()
        }
    }

    func showControls(_ show: Bool) {
        UIView.animate(withDuration: 0.25) {
            if show {
                self.controlButtonStackView.transform = .identity
                self.buttonShadowView.transform = .identity
                self.menuButton.transform = .identity
                self.topControlButtonStackView.transform = .identity
            } else {
                let upTransformation = CGAffineTransform(translationX: 0, y: 200)
                let downTransformation = CGAffineTransform(translationX: 0, y: -200)

                self.controlButtonStackView.transform = upTransformation
                self.buttonShadowView.transform = upTransformation
                self.menuButton.transform = downTransformation
                self.topControlButtonStackView.transform = downTransformation
            }
        }
    }

    @objc
    func topControlButtonTapped(_ sender: UIButton) {
        if traitCollection.verticalSizeClass == .compact {
            isContainerVisibleInLandscape.toggle()
            if isContainerVisibleInLandscape {
                scrollToSection?(sender.tag)
            }
        }
    }

    func makeTopControlButton(icon: UIImage?, title: String) -> TabBarButton {
        let button = TabBarButton(type: .system)

        button.setImage(icon, for: .normal)
        if #available(iOS 13.0, *) {
            button.tintColor = .systemBackground
        } else {
            button.tintColor = .white
        }
        button.setTitle(title, for: .normal)

        return button
    }
}

// MARK: - RoomMemberAudioObserver
extension ActiveMeetingView: RoomMemberAudioObserver {
    func roomMemberAudioStateDidChange(_ member: RoomMember, enabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.showMuteIcon(enabled == false)
        }
    }
}

// MARK: - RoomMemberVideoObserver
extension ActiveMeetingView: RoomMemberVideoObserver {
    func roomMemberVideoStateDidChange(_ member: RoomMember, enabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.showCamera(enabled)
        }
    }
}
