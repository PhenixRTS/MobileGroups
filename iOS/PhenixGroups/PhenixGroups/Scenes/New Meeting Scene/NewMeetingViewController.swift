//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

protocol DisplayNameDelegate: AnyObject {
    func saveDisplayName(_ displayName: String)
}

class NewMeetingViewController: UIViewController, Storyboarded {
    weak var coordinator: (ShowMeeting & JoinMeeting)?
    weak var phenix: (PhenixRoomCreation & PhenixRoomJoining)?
    weak var preferences: Preferences?

    var roomID: String?
    var device: UIDevice = .current
    var historyController: MeetingHistoryTableViewController!

    var newMeetingView: NewMeetingView {
        view as! NewMeetingView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

private extension NewMeetingViewController {
    func configure() {
        newMeetingView.configure(displayName: preferences?.displayName ?? device.name)
        newMeetingView.setDisplayNameDelegate(self)

        configureHistoryController()
        configureInteractions()
    }

    func configureInteractions() {
        configureNewMeetingHandler()
        configureJoinMeetingHandler()
    }

    func configureHistoryController() {
        let vc = MeetingHistoryTableViewController.instantiate()
        historyController = vc
        vc.delegate = newMeetingView
        add(vc) { childView in
            self.newMeetingView.setupHistoryView(childView)
        }
    }

    func configureNewMeetingHandler() {
        newMeetingView.setNewMeetingHandler { [weak self] _ in
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
                        self.historyController.addMeeting(roomID)

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
        newMeetingView.setJoinMeetingHandler { [weak self] displayName in
            self?.coordinator?.joinMeeting(displayName: displayName)
        }
    }
}

extension NewMeetingViewController: DisplayNameDelegate {
    func saveDisplayName(_ displayName: String) {
        preferences?.displayName = displayName
    }
}
