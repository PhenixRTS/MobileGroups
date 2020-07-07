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
    weak var phenix: PhenixRoomPublishing?
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

        configureMedia()
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
            self?.publishMeeting(with: .randomRoomAlias, displayName: displayName)
        }
    }

    func configureJoinMeetingHandler() {
        newMeetingView.setJoinMeetingHandler { [weak self] displayName in
            self?.coordinator?.joinMeeting(displayName: displayName)
        }
    }

    func configureControls() {
        newMeetingView.microphoneHandler = { [weak self] enabled in
            self?.setAudio(enabled: enabled)
        }

        newMeetingView.cameraHandler = { [weak self] enabled in
            self?.setVideo(enabled: enabled)
        }
    }

    func configureMedia() {
        guard let media = media else { return }
        media.providePreview { layer in
            self.newMeetingView.setCameraLayer(layer)
        }

        newMeetingView.setMicrophone(enabled: media.isAudioEnabled)
        newMeetingView.setCamera(enabled: media.isVideoEnabled)
    }

    func setVideo(enabled: Bool) {
         os_log(.debug, log: .newMeetingScene, "Set video enabled - %{PUBLIC}d", enabled)
        media?.setVideo(enabled: enabled)
    }

    func setAudio(enabled: Bool) {
         os_log(.debug, log: .newMeetingScene, "Set audio enabled - %{PUBLIC}d", enabled)
        media?.setAudio(enabled: enabled)
    }

    func publishMeeting(with code: String, displayName: String) {
        presentActivityIndicator()
        phenix?.publishRoom(withAlias: code, displayName: displayName) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let joinedRoom):
                os_log(.debug, log: .newMeetingScene, "Meeting created/joined, alias: %{PUBLIC}@", code)

                DispatchQueue.main.async {
                    self.dismissActivityIndicator {
                        self.coordinator?.showMeeting(joinedRoom)
                    }
                }

            case .failure(.failureStatus(let status)):
                os_log(.debug, log: .newMeetingScene, "Failed to create/join a meeting with alias: %{PUBLIC}@, status code: %{PUBLIC}d", code, status.rawValue)

                DispatchQueue.main.async {
                    self.dismissActivityIndicator {
                        self.presentAlert("Failed to create/join a meeting")
                    }
                }
            }
        }
    }
}

extension NewMeetingViewController: DisplayNameDelegate {
    func saveDisplayName(_ displayName: String) {
        preferences?.displayName = displayName
        newMeetingView.displayName = displayName
    }
}

extension NewMeetingViewController: MeetingHistoryDelegate {
    func rejoin(_ meeting: Meeting) {
        os_log(.debug, log: .newMeetingScene, "Rejoin meeting %{PUBLIC}@ (%{PRIVATE}@)", meeting.code, meeting.backendUrl.absoluteString)
        publishMeeting(with: meeting.code, displayName: displayName)
    }
}
