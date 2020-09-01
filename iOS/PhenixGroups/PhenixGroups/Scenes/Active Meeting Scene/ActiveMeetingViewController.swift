//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

protocol ActiveMeetingPreview: AnyObject {
    var focusedMember: RoomMember! { get }

    func setFocus(on member: RoomMember)
}

class ActiveMeetingViewController: UIViewController, Storyboarded {
    private var membersViewController: ActiveMeetingMemberListViewController!
    private var chatViewController: ActiveMeetingChatViewController!
    /// Disables audio when audio track is not accessible anymore for the application
    ///
    /// Most popular case is if other application requests the audio session, for example, device receives a phone call.
    ///
    /// In that case, PhenixCore does not receive the audio frame notifications and we are executing dispatch worker to inform other room users.
    private var audioDisablingWorker: DispatchWorkItem?
    /// Disables video when video track is not accessible anymore for the application
    ///
    /// Most popular case is if application gets backgrounded, video is automatically disabled by the system.
    ///
    /// In that case, PhenixCore does not receive the audio frame notifications and we are executing dispatch worker to inform other room users.
    private var videoDisablingWorker: DispatchWorkItem?
    /// Indicates that audio was interrupted
    private var audioWasInterrupted = false
    /// Indicates that video was interrupted
    private var videoWasInterrupted = false

    /// Contains a reference to the *RoomMember* instance, which is currently displayed in the view's *cameraView* (the main preview).
    var focusedMember: RoomMember! {
        didSet {
            os_log(.debug, log: .activeMeetingScene, "Focused member changed \n- from: %{PRIVATE}s, \n- to: %{PRIVATE}s", oldValue?.description ?? "None", focusedMember?.description ?? "None")
            if let previousMember = oldValue, previousMember != focusedMember {
                previousMember.removeAudioObserver(activeMeetingView)
                previousMember.removeVideoObserver(activeMeetingView)
                membersViewController.reloadVideoPreview(for: previousMember)
            }
        }
    }

    var displayName: String!

    weak var coordinator: MeetingFinished?
    weak var media: UserMediaStreamController?
    weak var joinedRoom: JoinedRoom!

    var activeMeetingView: ActiveMeetingView {
        view as! ActiveMeetingView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(joinedRoom != nil, "Joined meeting instance is necessary")
        assert(displayName != nil, "Display name is necessary")

        configure()
        setFocus(on: joinedRoom.currentMember)

        assert(focusedMember != nil, "Focused member is necessary")

        observeRoom()

        media?.audioFrameReadHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.enableAudioIfInterrupted()
                self?.checkForAudioInterruption()
            }
        }

        media?.videoFrameReadHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.enableVideoIfInterrupted()
                self?.checkForVideoInterruption()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureMedia()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        activeMeetingView.refreshLandscapePosition()
    }

    func observeRoom() {
        joinedRoom.subscribeToMemberList(membersViewController)
        joinedRoom.subscribeToChatMessages(chatViewController)

        chatViewController.sendMessageHandler = { [weak self] message in
            self?.joinedRoom.send(message: message)
        }
    }

    func leaveRoom() {
        os_log(.debug, log: .activeMeetingScene, "Leaving meeting")
        audioDisablingWorker?.cancel()
        videoDisablingWorker?.cancel()
        audioDisablingWorker = nil
        videoDisablingWorker = nil
        focusedMember = nil
        joinedRoom.leave()

        let meeting = Meeting(code: joinedRoom.alias ?? "N/A", leaveDate: .now, backendUrl: joinedRoom.backend)
        coordinator?.meetingFinished(meeting)
    }

    /// Configure UI elements to represent the current media state for current user
    func configureMedia() {
        guard let media = media else { return }

        // Set the preview layer from the local media for the "self" member, because "self" member does not subscribe
        // for the media stream.
        joinedRoom.currentMember.previewLayer = media.cameraLayer

        activeMeetingView.setCameraControl(enabled: media.isVideoEnabled)
        activeMeetingView.setMicrophoneControl(enabled: media.isAudioEnabled)

        configureMainPreview(for: joinedRoom.currentMember)
    }
}

private extension ActiveMeetingViewController {
    // MARK: - Configuration
    func configure() {
        activeMeetingView.configure(displayName: displayName)
        activeMeetingView.leaveMeetingHandler = { [weak self] in
            guard let self = self else { return }
            self.leaveRoom()
        }
        activeMeetingView.openMenuHandler = { [weak self] in
            self?.openMenu()
        }
        configureControls()
        configurePageController()
    }

    func configureControls() {
        activeMeetingView.microphoneHandler = { [weak self] enabled in
            if enabled {
                self?.audioWasInterrupted = false
            }
            self?.setAudio(enabled: enabled)
        }

        activeMeetingView.cameraHandler = { [weak self] enabled in
            if enabled {
                self?.videoWasInterrupted = false
            }
            self?.setVideo(enabled: enabled)
        }
    }

    func configureMainPreview(for member: RoomMember) {
        activeMeetingView.setMicrophone(enabled: member.isAudioAvailable)
        member.addAudioObserver(activeMeetingView)

        activeMeetingView.setCamera(placeholder: member.screenName)
        activeMeetingView.setCamera(layer: member.previewLayer)
        activeMeetingView.setCamera(enabled: member.isVideoAvailable)
        member.addVideoObserver(activeMeetingView)
    }

    func configurePageController() {
        let controllers = [
            makeMembersViewController(),
            makeChatViewController(),
            makeInformationViewController(code: joinedRoom.alias ?? "N/A")
        ]

        let pageController = PageViewController()
        pageController.setControllers(controllers)

        activeMeetingView.scrollToSection = { [weak pageController] sectionIndex in
            pageController?.selectTab(sectionIndex, withAnimation: false)
        }

        addChild(pageController)
        activeMeetingView.setPageView(pageController.view)
        pageController.didMove(toParent: self)

        for case let page as PageContainerMember in controllers {
            activeMeetingView.addTopControl(for: page)
        }
    }

    // MARK: - Controller factory

    func makeMembersViewController() -> UIViewController {
        let vc = ActiveMeetingMemberListViewController()
        membersViewController = vc
        vc.delegate = self
        return vc
    }

    func makeChatViewController() -> UIViewController {
        let vc = ActiveMeetingChatViewController()
        chatViewController = vc
        return vc
    }

    func makeInformationViewController(code: String) -> UIViewController {
        ActiveMeetingInformationViewController(code: code)
    }

    // MARK: - Audio & Video interaction

    func setAudio(enabled: Bool) {
        os_log(.debug, log: .activeMeetingScene, "Set audio enabled - %{PUBLIC}d", enabled)
        // Inform the joined room that the current audio state has changed
        joinedRoom.setAudio(enabled: enabled)
        // Inform the local media stream that the current audio state has changed.
        // This is needed to inform other controllers (like Join Meeting scene controller) that user has enabled/disabled the audio.
        media?.setAudio(enabled: enabled)
    }

    func setVideo(enabled: Bool) {
        os_log(.debug, log: .activeMeetingScene, "Set video enabled - %{PUBLIC}d", enabled)
        // Inform the joined room that the current video state has changed
        joinedRoom.setVideo(enabled: enabled)
        // Inform the local media stream that the current video state has changed.
        // This is needed to inform other controllers (like Join Meeting scene controller) that user has enabled/disabled the video.
        media?.setVideo(enabled: enabled)
    }

    /// Creates a timer to stop audio.
    ///
    /// This method first cancels previously created timer and creates a new one. If this method isn't called again, it will trigger the timer - therefore to disable the audio transmission.
    func checkForAudioInterruption() {
        // Cancel currently pending worker
        audioDisablingWorker?.cancel()

        guard media?.isAudioEnabled == true else {
            // We do not need to initiate a dispatch worker if user has disabled the audio.
            return
        }

        let worker = DispatchWorkItem { [weak self] in
            os_log(.debug, log: .activeMeetingScene, "Disable audio, no audio frames received for 1 second")
            self?.audioWasInterrupted = true
            self?.setAudio(enabled: false)
            self?.activeMeetingView.setMicrophoneControl(enabled: false)
        }
        audioDisablingWorker = worker

        // If the media audio frames haven't been received for 1 second, then execute the worker to disable the audio.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: worker)
    }

    /// Creates a timer to stop video.
    ///
    /// This method first cancels previously created timer and creates a new one. If this method isn't called again, it will trigger the timer - therefore to disable the video transmission.
    func checkForVideoInterruption() {
        // Cancel currently pending worker
        videoDisablingWorker?.cancel()

        guard media?.isVideoEnabled == true else {
            // We do not need to initiate a dispatch worker if user has disabled the video.
            return
        }

        let worker = DispatchWorkItem { [weak self] in
            os_log(.debug, log: .activeMeetingScene, "Disable video, no video frames received for 1 second")
            self?.videoWasInterrupted = true
            self?.setVideo(enabled: false)
            self?.activeMeetingView.setCameraControl(enabled: false)
        }
        videoDisablingWorker = worker

        // If the media video frames haven't been received for 1 second, then execute the worker to disable the video.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: worker)
    }

    func enableAudioIfInterrupted() {
        // Check if we need to re-enable the audio and activate the controls
        guard audioWasInterrupted == true else {
            return
        }

        os_log(.debug, log: .activeMeetingScene, "Re-enable audio, new audio frames received")
        audioWasInterrupted = false
        setAudio(enabled: true)
        activeMeetingView.setMicrophoneControl(enabled: true)
    }

    func enableVideoIfInterrupted() {
        // Check if we need to re-enable the video and activate the controls
        guard videoWasInterrupted == true else {
            return
        }

        os_log(.debug, log: .activeMeetingScene, "Re-enable video, new video frames received")
        videoWasInterrupted = false
        setVideo(enabled: true)
        activeMeetingView.setCameraControl(enabled: true)
    }

    // MARK: - Other functionality

    func openMenu() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "Switch camera", style: .default) { [weak self] _ in
            self?.media?.switchCamera()
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(actionSheet, animated: true)
    }
}

// MARK: - ActiveMeetingPreview
extension ActiveMeetingViewController: ActiveMeetingPreview {
    func setFocus(on member: RoomMember) {
        guard focusedMember != member else {
            return
        }
        configureMainPreview(for: member)
        focusedMember = member
    }
}
