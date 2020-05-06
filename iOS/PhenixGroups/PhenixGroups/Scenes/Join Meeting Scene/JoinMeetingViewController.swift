//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

class JoinMeetingViewController: UIViewController, Storyboarded {
    weak var coordinator: (ShowMeeting & JoinCancellation)?
    weak var phenix: PhenixRoomJoining?

    var displayName: String!

    var joinMeetingView: JoinMeetingView {
        view as! JoinMeetingView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(displayName != nil, "Display name is required")

        configure()
    }
}

private extension JoinMeetingViewController {
    func configure() {
        joinMeetingView.joinMeetingHandler = { [weak self] code in
            guard let self = self else { return }
            self.joinMeeting(code: code, displayName: self.displayName)
        }

        joinMeetingView.closeHandler = { [weak self] in
            guard let self = self else { return }
            self.coordinator?.cancel(self)
        }
    }

    func joinMeeting(code: String, displayName: String) {
        phenix?.joinRoom(with: .alias(code), displayName: displayName) { [weak self] error in
            guard let self = self else { return }
            switch error {
            case .none:
                os_log(.debug, log: .joinMeetingScene, "Joining meeting")
                DispatchQueue.main.async {
                    self.coordinator?.showMeeting()
                }
            case .failureStatus(let status):
                os_log(.debug, log: .joinMeetingScene, "Failed to create and/or connect to a meeting, status code: %{PUBLIC}d", status.rawValue)

                DispatchQueue.main.async {
                    self.presentAlert("Failed to join meeting")
                }
            }
        }
    }

    func presentAlert(_ title: String, message: String? = nil) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))

        present(ac, animated: true)
    }
}
