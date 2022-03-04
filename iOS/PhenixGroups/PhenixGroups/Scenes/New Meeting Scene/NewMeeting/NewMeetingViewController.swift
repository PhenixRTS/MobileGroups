//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

class NewMeetingViewController: UIViewController, Storyboarded {
    private static let logger = OSLog(identifier: "NewMeetingViewController")

    // swiftlint:disable:next force_cast
    private var contentView: NewMeetingView { view as! NewMeetingView }

    weak var coordinator: (ShowMeeting & JoinMeeting)?
    var viewModel: ViewModel!
    var meetingHistoryViewController: MeetingHistoryTableViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(viewModel != nil, "ViewModel should exist!")
        assert(meetingHistoryViewController != nil, "MeetingHistoryViewController should exist!")

        viewModel.delegate = self
        contentView.delegate = self

        configureView()

        meetingHistoryViewController.observeMeetings()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureMediaAppearance()
        subscribeForEvents()
        viewModel.setupLocalMediaIfNeeded()
    }

    func subscribeForEvents() {
        viewModel.subscribeForEvents()
    }

    // MARK: - Private methods

    private func configureView() {
        configureHistoryView()
        contentView.configure(displayName: viewModel.displayName)
    }

    private func configureMediaAppearance() {
        viewModel.preview(on: contentView.cameraLayer)

        setVideo(enabled: viewModel.isCameraEnabled)
        setAudio(enabled: viewModel.isMicrophoneEnabled)
    }

    private func configureHistoryView() {
        add(meetingHistoryViewController) { childView in
            self.contentView.setupHistoryView(childView)
        }
    }

    private func setVideo(enabled: Bool) {
        os_log(.debug, log: Self.logger, "Set video %{public}s", enabled ? "enabled" : "disabled")
        viewModel.setCamera(enabled: enabled)
        contentView.setCamera(visible: enabled)
        contentView.setCameraControlButton(active: enabled)
    }

    private func setAudio(enabled: Bool) {
        os_log(.debug, log: Self.logger, "Set audio %{public}s", enabled ? "enabled" : "disabled")
        viewModel.setMicrophone(enabled: enabled)
        contentView.setMicrophoneMuteIcon(visible: enabled == false)
        contentView.setMicrophoneControlButton(active: enabled)
    }
}

// MARK: - MeetingHistoryDelegate
extension NewMeetingViewController: MeetingHistoryTableViewControllerDelegate {
    func join(_ meeting: Meeting) {
        os_log(.debug, log: Self.logger, "Rejoin meeting: %{public}s", meeting.code)
        viewModel.join(meetingCode: meeting.code)
    }
}

// MARK: - NewMeetingViewDelegate
extension NewMeetingViewController: NewMeetingViewDelegate {
    func newMeetingView(_ view: NewMeetingView, didChangeCameraState enabled: Bool) {
        setVideo(enabled: enabled)
    }

    func newMeetingView(_ view: NewMeetingView, didChangeMicrophoneState enabled: Bool) {
        setAudio(enabled: enabled)
    }

    func newMeetingView(_ view: NewMeetingView, didChangeDisplayName displayName: String) {
        contentView.setCamera(placeholder: displayName)
        viewModel.displayName = displayName
    }

    func newMeetingViewDidTapMenuButton(_ view: NewMeetingView) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Switch camera", style: .default) { [weak self] _ in
            self?.viewModel.flipCamera()
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(actionSheet, animated: true)
    }

    func newMeetingViewDidTapNewMeetingButton(_ view: NewMeetingView) {
        let meetingCode = String.randomMeetingCode
        os_log(.debug, log: Self.logger, "Join meeting: %{public}s", meetingCode)
        viewModel.join(meetingCode: meetingCode)
    }

    func newMeetingViewDidTapJoinMeetingButton(_ view: NewMeetingView) {
        viewModel.unsubscribeFromEvents()
        coordinator?.showJoinMeeting()
    }
}

// MARK: - NewMeetingViewModelDelegate
extension NewMeetingViewController: NewMeetingViewModelDelegate {
    func newMeetingViewModel(_ view: ViewModel, willJoinMeeting meetingCode: String) {
        presentActivityIndicator()
    }

    func newMeetingViewModel(_ view: ViewModel, didJoinMeeting meetingCode: String) {
        os_log(.debug, log: Self.logger, "Meeting joined, alias: %{public}s", meetingCode)
        viewModel.unsubscribeFromEvents()
        dismissActivityIndicator { [weak self] in
            self?.coordinator?.showMeeting()
        }
    }

    func newMeetingViewModel(_ view: ViewModel, didFailToJoinMeetingWith description: String?) {
        os_log(.debug, log: Self.logger, "Failed to join meeting: %{public}s", description ?? "n/a")
        dismissActivityIndicator()
    }

    func newMeetingViewModelWillSetupLocalMedia(_ view: ViewModel) {
        presentActivityIndicator()
    }

    func newMeetingViewModelDidSetupLocalMedia(_ view: ViewModel) {
        configureMediaAppearance()
        dismissActivityIndicator { [weak self] in
            self?.viewModel.joinMeetingIfNecessary()
        }
    }

    func newMeetingViewModelDidFailToSetupLocalMedia(_ view: ViewModel) {
        dismissActivityIndicator {
            AppDelegate.present(alertWithTitle: "Failed to initiate local media", message: "Please restart the app.")
        }
    }
}

// MARK: - String
fileprivate extension String {
    static var randomMeetingCode: String {
        let symbols = "abcdefghijklmnopqrstuvwxyz"

        let firstPart = symbols.randomElements(3)
        let secondPart = symbols.randomElements(4)
        let thirdPart = symbols.randomElements(3)

        return "\(firstPart)-\(secondPart)-\(thirdPart)"
    }

    private func randomElements(_ maxLength: Int) -> String {
        guard isEmpty == false else {
            return ""
        }

        var string = ""

        for _ in 0..<maxLength {
            // swiftlint:disable force_unwrapping
            string.append(randomElement()!)
        }

        return string
    }
}
