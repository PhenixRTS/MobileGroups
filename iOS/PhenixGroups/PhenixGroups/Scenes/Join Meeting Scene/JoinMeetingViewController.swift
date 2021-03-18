//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

class JoinMeetingViewController: UIViewController, Storyboarded {
    weak var coordinator: (ShowMeeting & JoinCancellation)?
    weak var phenix: PhenixRoomPublishing?

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

// MARK: - Private methods
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
        os_log(.debug, log: .joinMeetingScene, "Join meeting with alias %{PUBLIC}s", code)
        presentActivityIndicator()
        phenix?.publishRoom(withAlias: code, displayName: displayName) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let joinedRoom):
                os_log(.debug, log: .joinMeetingScene, "Joined meeting with alias %{PUBLIC}s", code)

                DispatchQueue.main.async {
                    self.dismissActivityIndicator {
                        self.coordinator?.showMeeting(joinedRoom)
                    }
                }

            case .failure(.failureStatus(let status)):
                os_log(.debug, log: .joinMeetingScene, "Failed to join a meeting with alias: %{PUBLIC}s, status code: %{PUBLIC}d", code, status.rawValue)

                DispatchQueue.main.async {
                    self.dismissActivityIndicator {
                        AppDelegate.present(
                            alertWithTitle: "Failed to join a meeting",
                            message: "(\(status.description))"
                        )
                    }
                }

            case .failure(.noMediaAvailable):
                os_log(.debug, log: .newMeetingScene, "Failed to publish to a meeting with alias: %{PUBLIC}s, no media available", code)

                DispatchQueue.main.async {
                    self.dismissActivityIndicator {
                        AppDelegate.present(
                            alertWithTitle: "Experiencing problems with local media",
                            message: "Check your network status."
                        )
                    }
                }
            }
        }
    }
}
