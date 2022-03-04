//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Combine
import PhenixCore
import UIKit

class ActiveMeetingView: UIView {
    private lazy var muteImage: UIImageView = {
        let view = UIImageView.makeMuteImageView()
        return view
    }()

    private lazy var menuButton: UIButton = {
        let button = UIButton.makeMenuButton()
        button.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var topControlButtonStackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 16
        view.isHidden = traitCollection.verticalSizeClass != .compact
        return view
    }()

    private var cancellables = Set<AnyCancellable>()
    private var menuButtonConstraintToTopControlButtons: NSLayoutConstraint!

    private var isContainerVisibleInLandscape = false {
        didSet { showContainerInLandscape(isContainerVisibleInLandscape) }
    }

    private var isControlsVisible = true {
        didSet { showControls(isControlsVisible) }
    }

    weak var delegate: ActiveMeetingViewDelegate?

    @IBOutlet private var cameraView: CameraView! {
        didSet {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cameraViewTapped))
            cameraView.addGestureRecognizer(tapGesture)
        }
    }
    @IBOutlet private var buttonShadowView: UIView!
    @IBOutlet private var controlButtonStackView: UIStackView!
    @IBOutlet private var microphoneButton: ControlButton! {
        didSet { microphoneButton.configureAsMicrophoneButton() }
    }
    @IBOutlet private var leaveMeetingButton: ControlButton! {
        didSet { leaveMeetingButton.configureAsLeaveMeetingButton() }
    }
    @IBOutlet private var cameraButton: ControlButton! {
        didSet { cameraButton.configureAsCameraButton() }
    }
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var containerViewBottomConstraint: NSLayoutConstraint!
    // Constraint positions container view leading anchor to be equal with view trailing anchor.
    // It pushes the container view outside of the visible view part.
    @IBOutlet private var containerViewLandscapeConstraint: NSLayoutConstraint!

    @IBAction
    private func leaveMeetingTapped(_ sender: ControlButton) {
        delegate?.activeMeetingViewDidTapLeaveMeetingButton(self)
    }

    @IBAction
    private func microphoneButtonTapped(_ sender: ControlButton) {
        sender.controlState.toggle()
        delegate?.activeMeetingView(self, didChangeMicrophoneState: sender.controlState == .on)
    }

    @IBAction
    private func cameraButtonTapped(_ sender: ControlButton) {
        sender.controlState.toggle()
        delegate?.activeMeetingView(self, didChangeCameraState: sender.controlState == .on)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        topControlButtonStackView.isHidden = traitCollection.verticalSizeClass != .compact
        isContainerVisibleInLandscape = false
    }

    func getMainPreviewLayer() -> CALayer {
        cameraView.cameraLayer
    }

    func configure(displayName: String) {
        cameraView.placeholderText = displayName

        addSubview(muteImage)
        addSubview(menuButton)
        insertSubview(topControlButtonStackView, aboveSubview: cameraView)

        NSLayoutConstraint.activate([
            muteImage.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: -8),
            muteImage.centerYAnchor.constraint(equalTo: microphoneButton.centerYAnchor),
            muteImage.widthAnchor.constraint(equalToConstant: 44),
            muteImage.heightAnchor.constraint(equalToConstant: 44),

            topControlButtonStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            topControlButtonStackView.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            ),

            menuButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
            menuButton.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor, constant: -8),
            menuButton.widthAnchor.constraint(equalToConstant: 44),
            menuButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        subscribeToNotifications()
    }

    // MARK: - Media control

    func setMicrophoneMuteIcon(visible: Bool) {
        showMuteIcon(visible)
    }

    func setMicrophoneControlButton(active: Bool) {
        setControl(microphoneButton, enabled: active)
    }

    func setCamera(visible: Bool) {
        showCamera(visible)
    }

    func setCamera(placeholder text: String) {
        cameraView.placeholderText = text
    }

    func setCameraControlButton(active: Bool) {
        setControl(cameraButton, enabled: active)
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

    // MARK: - Other

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

    // MARK: - Private methods

    private func setControl(_ control: ControlButton, enabled: Bool) {
        control.controlState = enabled == true ? .on : .off
    }

    private func showMuteIcon(_ show: Bool) {
        muteImage.isHidden = show == false
    }

    private func showCamera(_ show: Bool) {
        cameraView.showCamera = show
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
    private func adjustForKeyboard(notification: Notification) {
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

        if notification.name == UIResponder.keyboardWillHideNotification {
            containerViewBottomConstraint.constant = 0
        } else {
            let keyboardScreenEndFrame = keyboardValue.cgRectValue
            let keyboardViewEndFrame = convert(keyboardScreenEndFrame, from: window)
            containerViewBottomConstraint.constant = keyboardViewEndFrame.height - safeAreaInsets.bottom
        }

        UIView.animate(withDuration: keyboardAnimation) {
            self.window?.layoutIfNeeded()
        }
    }

    @objc
    private func menuButtonTapped() {
        delegate?.activeMeetingViewDidTapMenuButton(self)
    }

    private func showContainerInLandscape(_ show: Bool, withAnimation: Bool = true) {
        guard traitCollection.verticalSizeClass == .compact else {
            return
        }

        // By activating `containerViewLandscapeConstraint`
        // control view will hide, and by deactivating - show.

        containerViewLandscapeConstraint.isActive = !show

        UIView.animate(withDuration: withAnimation ? 0.25 : 0) {
            self.layoutIfNeeded()
        }
    }

    private func showControls(_ show: Bool) {
        UIView.animate(withDuration: 0.25) {
            if show {
                self.menuButton.transform = .identity
                self.buttonShadowView.transform = .identity
                self.controlButtonStackView.transform = .identity
                self.topControlButtonStackView.transform = .identity
            } else {
                let upTransformation = CGAffineTransform(translationX: 0, y: 200)
                let downTransformation = CGAffineTransform(translationX: 0, y: -200)

                self.menuButton.transform = downTransformation
                self.buttonShadowView.transform = upTransformation
                self.controlButtonStackView.transform = upTransformation
                self.topControlButtonStackView.transform = downTransformation
            }
        }
    }

    @objc
    private func topControlButtonTapped(_ sender: UIButton) {
        if traitCollection.verticalSizeClass == .compact {
            isContainerVisibleInLandscape.toggle()
            if isContainerVisibleInLandscape {
                delegate?.activeMeetingView(self, didScrollTillSectionWithIndex: sender.tag)
            }
        }
    }

    private func makeTopControlButton(icon: UIImage?, title: String) -> TabBarButton {
        let button = TabBarButton(type: .system)

        button.setImage(icon, for: .normal)
        button.tintColor = .systemBackground
        button.setTitle(title, for: .normal)

        return button
    }
}
