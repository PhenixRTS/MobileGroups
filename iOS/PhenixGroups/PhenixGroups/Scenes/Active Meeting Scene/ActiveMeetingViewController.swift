//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

class ActiveMeetingViewController: UIViewController, Storyboarded {
    weak var coordinator: MeetingFinished?
    weak var phenix: PhenixRoomLeaving?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction
    private func leaveMeetingTapped(_ sender: UIButton) {
        os_log(.debug, log: .activeMeetingScene, "Leaving meeting")
        phenix?.leaveRoom()
        coordinator?.meetingFinished()
    }
}
