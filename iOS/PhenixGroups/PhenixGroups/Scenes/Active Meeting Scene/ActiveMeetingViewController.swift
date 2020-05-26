//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

class ActiveMeetingViewController: UIViewController, Storyboarded {
    weak var coordinator: MeetingFinished?
    weak var media: UserMediaStreamController?

    var displayName: String!
    var joinedRoom: JoinedRoom!

    var activeMeetingView: ActiveMeetingView {
        view as! ActiveMeetingView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(joinedRoom != nil, "Joined meeting instance is necessary")
        assert(displayName != nil, "Display name is necessary")

        configure()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureMedia()
    }

    func leave() {
        os_log(.debug, log: .activeMeetingScene, "Leaving meeting")
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
    }

    func configureControls() {
        activeMeetingView.microphoneHandler = { [weak self] enabled in
            self?.setAudio(enabled: enabled)
        }

        activeMeetingView.cameraHandler = { [weak self] enabled in
            self?.setVideo(enabled: enabled)
        }
    }

    func configureMedia() {
        guard let media = media else { return }
        media.providePreview { layer in
            self.activeMeetingView.setCameraLayer(layer)
        }

        joinedRoom.setAudio(enabled: media.isAudioEnabled)
        joinedRoom.setVideo(enabled: media.isVideoEnabled)

        activeMeetingView.setMicrophone(enabled: media.isAudioEnabled)
        activeMeetingView.setCamera(enabled: media.isVideoEnabled)
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
}
