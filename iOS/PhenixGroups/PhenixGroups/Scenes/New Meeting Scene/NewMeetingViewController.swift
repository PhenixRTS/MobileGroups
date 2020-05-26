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
    weak var media: UserMediaStreamController?
    weak var preferences: Preferences?

    var device: UIDevice = .current
    var historyController: MeetingHistoryTableViewController!

    var newMeetingView: NewMeetingView {
        view as! NewMeetingView
    }

    var displayName: String {
        newMeetingView.displayName
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        media?.setPreview(on: newMeetingView.camera)
    }
}

private extension NewMeetingViewController {
    func configure() {
        newMeetingView.configure(displayName: preferences?.displayName ?? device.name)
        newMeetingView.setDisplayNameDelegate(self)

        configureHistoryView()
        configureInteractions()
    }

    func configureInteractions() {
        configureNewMeetingHandler()
        configureJoinMeetingHandler()
        configureControls()
    }

    func configureHistoryView() {
        add(historyController) { childView in
            self.newMeetingView.setupHistoryView(childView)
        }
    }

    func configureNewMeetingHandler() {
        newMeetingView.setNewMeetingHandler { [weak self] displayName in
            guard let self = self else { return }
            guard let phenix = self.phenix else { return }

            phenix.createRoom(withAlias: .randomRoomAlias) { result in
                switch result {
                case .success(let room):
                    os_log(.debug, log: .newMeetingScene, "Meeting created")

                    guard let alias = room.getObservableAlias()?.getValue() as String? else {
                        return
                    }

                    self.joinMeeting(code: alias, displayName: displayName)

                case .failure(.failureStatus(let status)):
                    os_log(.debug, log: .newMeetingScene, "Failed to create a meeting, status code: %{PUBLIC}d", status.rawValue)

                    DispatchQueue.main.async {
                        self.presentAlert("Failed to create a meeting")
                    }
                }
            }
        }
    }

    func configureJoinMeetingHandler() {
        newMeetingView.setJoinMeetingHandler { [weak self] displayName in
            self?.coordinator?.joinMeeting(displayName: displayName)
        }
    }

    func configureControls() {
        newMeetingView.microphoneHandler = { [weak media] enabled in
            media?.setAudioEnabled(enabled)
        }

        newMeetingView.cameraHandler = { [weak media] enabled in
            media?.setVideoEnabled(enabled)
        }
    }

    func joinMeeting(code: String, displayName: String) {
        phenix?.joinRoom(with: .alias(code), displayName: displayName) { [weak self] error in
            guard let self = self else { return }
            switch error {
            case .none:
                os_log(.debug, log: .newMeetingScene, "Joined meeting with alias %{PUBLIC}@", code)
                DispatchQueue.main.async {
                    self.coordinator?.showMeeting(code: code)
                }

            case .failureStatus(let status):
                os_log(.debug, log: .newMeetingScene, "Failed to join a meeting with alias: %{PUBLIC}@, status code: %{PUBLIC}d", code, status.rawValue)

                DispatchQueue.main.async {
                    self.presentAlert("Failed to join a meeting")
                }
            }
        }
    }
}

extension NewMeetingViewController: DisplayNameDelegate {
    func saveDisplayName(_ displayName: String) {
        preferences?.displayName = displayName
    }
}

extension NewMeetingViewController: MeetingHistoryDelegate {
    func rejoin(_ meeting: Meeting) {
        os_log(.debug, log: .newMeetingScene, "Rejoin meeting %{PUBLIC}@ (%{PRIVATE}@)", meeting.code, meeting.backendUrl.absoluteString)
        phenix?.joinRoom(with: .alias(meeting.code), displayName: displayName) { [weak self] error in
            guard let self = self else { return }
            switch error {
            case .none:
                os_log(.debug, log: .newMeetingScene, "Joined meeting with alias %{PUBLIC}@", meeting.code)
                DispatchQueue.main.async {
                    self.coordinator?.showMeeting(code: meeting.code)
                }

            case .failureStatus(let status):
                os_log(.debug, log: .newMeetingScene, "Failed to join a meeting with alias: %{PUBLIC}@, status code: %{PUBLIC}d", meeting.code, status.rawValue)

                DispatchQueue.main.async {
                    self.presentAlert("Failed to join a meeting")
                }
            }
        }
    }
}
