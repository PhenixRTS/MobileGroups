//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

class NewMeetingViewController: UIViewController, Storyboarded {
    weak var coordinator: Meeting?
    weak var phenix: (PhenixRoomCreation & PhenixRoomJoining)?

    var roomID: String?
    var device: UIDevice = .current

    @IBOutlet private var controlView: NewMeetingControlView!

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        controlView.displayName = device.name
    }
}

private extension NewMeetingViewController {
    func configure() {
        configureNewMeetingHandler()
        configureJoinMeetingHandler()
    }

    func configureNewMeetingHandler() {
        controlView.newMeetingTapHandler = { [weak self] displayName in
            guard let self = self else { return }

            self.phenix?.createRoom(withAlias: .randomRoomAlias) { result in
                switch result {
                case .success(let room):
                    os_log(.debug, log: .newMeetingScene, "Meeting created and joined")
                    guard let roomID = room.getId() else {
                        fatalError("Could not get Room ID")
                    }
                    self.roomID = roomID

                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Room created", message: "Room ID: \(roomID)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }

                case .failure(.failureStatus(let status)):
                    os_log(.debug, log: .newMeetingScene, "Failed to create a meeting, status code: %{PUBLIC}d", status.rawValue)
                    self.roomID = nil
                }
            }
        }
    }

    func configureJoinMeetingHandler() {
        controlView.joinMeetingTapHandler = { [weak self] displayName in
            guard let self = self else { return }
            guard let roomID = self.roomID else {
                let alert = UIAlertController(title: "Room not created", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))

                DispatchQueue.main.async {
                    self.present(alert, animated: true)
                }
                return
            }

            self.phenix?.joinRoom(with: .identifier(roomID), displayName: displayName) { error in
                switch error {
                case .none:
                    os_log(.debug, log: .newMeetingScene, "Joining meeting")
                    self.coordinator?.showMeeting()

                case .failureStatus(let status):
                    os_log(.debug, log: .newMeetingScene, "Failed to create and/or connect to a meeting, status code: %{PUBLIC}d", status.rawValue)
                }
            }
        }
    }
}
