//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

class ActiveMeetingViewController: UIViewController, Storyboarded {
    weak var coordinator: MeetingFinished?
    weak var media: UserMediaStreamController?

    var joinedRoom: JoinedRoom!

    var activeMeetingView: ActiveMeetingView {
        view as! ActiveMeetingView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(joinedRoom != nil, "Joined meeting instance is necessary")

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
        activeMeetingView.configure()
        activeMeetingView.leaveMeetingHandler = { [weak self] in
            guard let self = self else { return }
            self.leave()
        }
        configureControls()
    }

    func configureControls() {
        activeMeetingView.microphoneHandler = { [weak media] enabled in
            media?.setAudioEnabled(enabled)
        }

        activeMeetingView.cameraHandler = { [weak media] enabled in
            media?.setVideoEnabled(enabled)
        }
        configureControls()
    }

    func configureControls() {
        activeMeetingView.microphoneHandler = { [weak media] enabled in
            media?.setAudioEnabled(enabled)
        }

        activeMeetingView.cameraHandler = { [weak media] enabled in
            media?.setVideoEnabled(enabled)
        }
    }

    func configureMedia() {
        guard let media = media else { return }
        media.setPreview(on: activeMeetingView.camera)
        activeMeetingView.setMicrophoneButtonStateEnabled(media.isAudioEnabled)
        activeMeetingView.setCameraButtonStateEnabled(media.isVideoEnabled)
    }

    func configureMedia() {
        guard let media = media else { return }
        media.setPreview(on: activeMeetingView.camera)
        activeMeetingView.setMicrophoneButtonStateEnabled(media.isAudioEnabled)
        activeMeetingView.setCameraButtonStateEnabled(media.isVideoEnabled)
    }
}
