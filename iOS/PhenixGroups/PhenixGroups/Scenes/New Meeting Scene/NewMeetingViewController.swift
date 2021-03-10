//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

protocol DisplayNameDelegate: AnyObject {
    func saveDisplayName(_ displayName: String)
}

class NewMeetingViewController: UIViewController, Storyboarded {
    weak var coordinator: (ShowMeeting & JoinMeeting & ShowDebugMenu)?
    weak var phenix: (PhenixRoomPublishing & PhenixMediaChanges)?
    weak var media: UserMediaStreamController?
    weak var preferences: Preferences?

    var device: UIDevice = .current
    var historyController: MeetingHistoryTableViewController!
    var initialMeetingCode: String?

    var newMeetingView: NewMeetingView {
        view as! NewMeetingView
    }

    var displayName: String {
        newMeetingView.displayName
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        phenix?.addUserStreamMediaControllerObserver(self)
        configureView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureMedia()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        publishInitialMeetingIfNeeded()
    }

    func publishInitialMeetingIfNeeded() {
        guard let code = initialMeetingCode else {
            return
        }

        publishMeeting(with: code, displayName: displayName)
        // Remove initial meeting code so that next time the view appears,
        // it would not automatically start to join the meeting again.
        initialMeetingCode = nil
    }
}

// MARK: - Private methods
private extension NewMeetingViewController {
    func configureView() {
        newMeetingView.configure(displayName: preferences?.displayName ?? device.name)
        newMeetingView.setDisplayNameDelegate(self)
        newMeetingView.openMenuHandler = { [weak self] in
            self?.openMenu()
        }
        newMeetingView.cameraViewMultipleTapHandler = { [weak self] in
            self?.coordinator?.showDebugMenu()
        }
        newMeetingView.isMediaAvailable = { [weak self] in
            self?.media != nil
        }

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
        newMeetingView.setCamera(layer: media?.cameraLayer)
        newMeetingView.setCamera(enabled: media?.isVideoEnabled ?? false)
        newMeetingView.setMicrophone(enabled: media?.isAudioEnabled ?? false)
    }

    func setVideo(enabled: Bool) {
         os_log(.debug, log: .newMeetingScene, "Set video %{PUBLIC}s", enabled == true ? "enabled" : "disabled")
        media?.setVideo(enabled: enabled)
    }

    func setAudio(enabled: Bool) {
         os_log(.debug, log: .newMeetingScene, "Set audio %{PUBLIC}s", enabled == true ? "enabled" : "disabled")
        media?.setAudio(enabled: enabled)
    }

    func publishMeeting(with code: String, displayName: String) {
        presentActivityIndicator()
        phenix?.publishRoom(withAlias: code, displayName: displayName) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let joinedRoom):
                os_log(.debug, log: .newMeetingScene, "Meeting created/joined, alias: %{PUBLIC}s", code)

                DispatchQueue.main.async {
                    self.dismissActivityIndicator {
                        self.coordinator?.showMeeting(joinedRoom)
                    }
                }

            case .failure(.failureStatus(let status)):
                os_log(.debug, log: .newMeetingScene, "Failed to create/join a meeting with alias: %{PUBLIC}s, status code: %{PUBLIC}d", code, status.rawValue)

                DispatchQueue.main.async {
                    self.dismissActivityIndicator {
                        AppDelegate.present(alertWithTitle: "Failed to create/join a meeting (\(status.rawValue))")
                    }
                }

            case .failure(.noMediaAvailable):
                os_log(.debug, log: .newMeetingScene, "Failed to publish to a meeting with alias: %{PUBLIC}s, no media available", code)

                DispatchQueue.main.async {
                    self.dismissActivityIndicator {
                        AppDelegate.present(alertWithTitle: "Experiencing problems with local media. Check your network status.")
                    }
                }
            }
        }
    }

    func openMenu() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "Switch camera", style: .default) { [weak self] _ in
            self?.media?.switchCamera()
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(actionSheet, animated: true)
    }
}

// MARK: - DisplayNameDelegate
extension NewMeetingViewController: DisplayNameDelegate {
    func saveDisplayName(_ displayName: String) {
        preferences?.displayName = displayName
        newMeetingView.displayName = displayName
    }
}

// MARK: - MeetingHistoryDelegate
extension NewMeetingViewController: MeetingHistoryDelegate {
    func rejoin(_ meeting: Meeting) {
        os_log(.debug, log: .newMeetingScene, "Rejoin meeting %{PUBLIC}s (%{PRIVATE}s)", meeting.code, meeting.backendUrl.absoluteString)
        publishMeeting(with: meeting.code, displayName: displayName)
    }
}

// MARK: - PhenixUserStreamMediaObserver
extension NewMeetingViewController: PhenixUserStreamMediaObserver {
    func userStreamMediaControllerDidChange(_ controller: UserMediaStreamController) {
        DispatchQueue.main.async { [weak self] in
            self?.media = controller
            self?.configureMedia()
        }
    }
}
