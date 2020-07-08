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

    var focusedMember: RoomMember! {
        didSet {
            if let previousMember = oldValue, previousMember != focusedMember {
                previousMember.removeVideoObserver(activeMeetingView)
                membersViewController.reloadVideoPreview(for: previousMember)
            }
        }
    }

    weak var coordinator: MeetingFinished?
    weak var media: UserMediaStreamController?

    var displayName: String!
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

        joinedRoom.subscribeToMemberList(membersViewController)
        joinedRoom.subscribeToChatMessages(chatViewController)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureMedia()
    }

    func leave() {
        os_log(.debug, log: .activeMeetingScene, "Leaving meeting")
        focusedMember = nil
        joinedRoom.leave()

        let meeting = Meeting(code: joinedRoom.alias ?? "N/A", leaveDate: .now, backendUrl: joinedRoom.backend)
        coordinator?.meetingFinished(meeting)
    }
}

private extension ActiveMeetingViewController {
    func configure() {
        activeMeetingView.configure(displayName: displayName)
        activeMeetingView.leaveMeetingHandler = { [weak self] in
            guard let self = self else { return }
            self.leave()
        }
        configureControls()
        configurePageController()
    }

    func configureControls() {
        activeMeetingView.microphoneHandler = { [weak self] enabled in
            self?.setAudio(enabled: enabled)
            self?.joinedRoom.currentMember.isAudioAvailable = enabled
        }

        activeMeetingView.cameraHandler = { [weak self] enabled in
            self?.setVideo(enabled: enabled)
            self?.joinedRoom.currentMember.isVideoAvailable = enabled
        }
    }

    func configureMedia() {
        guard let media = media else { return }

        joinedRoom.setAudio(enabled: media.isAudioEnabled)
        joinedRoom.setVideo(enabled: media.isVideoEnabled)

        joinedRoom.currentMember.previewLayer = media.cameraLayer
        joinedRoom.currentMember.isVideoAvailable = media.isVideoEnabled
        joinedRoom.currentMember.isAudioAvailable = media.isAudioEnabled

        activeMeetingView.setCameraControl(enabled: media.isVideoEnabled)
        activeMeetingView.setMicrophoneControl(enabled: media.isAudioEnabled)

        configureMainPreview(for: joinedRoom.currentMember)
    }

    func configureMainPreview(for member: RoomMember) {
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

        addChild(pageController)
        activeMeetingView.setPageView(pageController.view)
        pageController.didMove(toParent: self)
    }

    func makeMembersViewController() -> UIViewController {
        let vc = ActiveMeetingMemberListViewController()
        membersViewController = vc
        vc.delegate = self
        return vc
    }

    func makeChatViewController() -> UIViewController {
        let vc = ActiveMeetingChatViewController()

        chatViewController = vc
        vc.sendMessageHandler = { [weak self] message in
            self?.joinedRoom.send(message: message)
        }

        return vc
    }

    func makeInformationViewController(code: String) -> UIViewController {
        ActiveMeetingInformationViewController(code: code)
    }

    func setVideo(enabled: Bool) {
        os_log(.debug, log: .activeMeetingScene, "Set video enabled - %{PUBLIC}d", enabled)
        joinedRoom.setVideo(enabled: enabled)
        media?.setVideo(enabled: enabled)
    }

    func setAudio(enabled: Bool) {
        os_log(.debug, log: .activeMeetingScene, "Set audio enabled - %{PUBLIC}d", enabled)
        joinedRoom.setAudio(enabled: enabled)
        media?.setAudio(enabled: enabled)
    }

    func focusedMemberChanged(_ member: RoomMember) {
        configureMainPreview(for: member)
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
