//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

class ActiveMeetingViewController: UIViewController, Storyboarded {
    weak var coordinator: MeetingFinished?
    weak var phenix: (PhenixRoomLeaving & PhenixInformation)?
    weak var media: UserMediaStreamController?

    var code: String!

    var activeMeetingView: ActiveMeetingView {
        view as! ActiveMeetingView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(code != nil, "Meeting code is necessary")

        configure()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureMedia()
    }
}

private extension ActiveMeetingViewController {
    func configure() {
        activeMeetingView.configure()
        activeMeetingView.leaveMeetingHandler = { [weak self] in
            guard let self = self else { return }
            guard let phenix = self.phenix else { return }

            os_log(.debug, log: .activeMeetingScene, "Leaving meeting")
            self.phenix?.leaveRoom()

            #warning("Fix issue with creating a new Meeting instance in preferences after re-joining from history Meeting. Do not create a new instance but just update previous instance.")
            let meeting = Meeting(code: self.code, leaveDate: .now, backendUrl: phenix.backendUri)
            self.coordinator?.meetingFinished(meeting)
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        media?.setPreview(on: activeMeetingView.camera)
    }
}
