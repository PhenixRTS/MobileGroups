//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

class ActiveMeetingViewController: UIViewController, Storyboarded {
    weak var coordinator: MeetingFinished?
    weak var phenix: (PhenixRoomLeaving & PhenixInformation)?

    var code: String!

    var activeMeetingView: ActiveMeetingView {
        view as! ActiveMeetingView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(code != nil, "Meeting code is necessary")

        activeMeetingView.configure()
        activeMeetingView.leaveMeetingHandler = { [weak self] in
            guard let self = self else { return }
            guard let phenix = self.phenix else { return }

            os_log(.debug, log: .activeMeetingScene, "Leaving meeting")
            self.phenix?.leaveRoom()

            #warning("Fix issue with creating a new Meeting instance in preferences after re-joining from history Meeting. Do not create a new instance but just update previous instance.")
            let meeting = Meeting(code: self.code, leaveDate: .now, url: phenix.backendUri)
            self.coordinator?.meetingFinished(meeting)
        }
    }
}
