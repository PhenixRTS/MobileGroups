//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

class ActiveMeetingViewController: UIViewController, Storyboarded {
    private static let logger = OSLog(identifier: "ActiveMeetingViewController")

    // swiftlint:disable:next force_cast
    private var contentView: ActiveMeetingView { view as! ActiveMeetingView }
    private var loudestMemberTimer: Timer?

    var viewModel: ViewModel!
    var pageController: PageViewController!

    weak var coordinator: MeetingFinished?

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(viewModel != nil, "ViewModel should exist!")
        assert(pageController != nil, "PageController should exist!")

        viewModel.delegate = self
        contentView.delegate = self

        configureView()
        configurePageController()

        viewModel.subscribeForEvents()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        contentView.refreshLandscapePosition()
    }

    func leaveRoom(withReason reason: (title: String, message: String?)? = nil) {
        os_log(.debug, log: Self.logger, "Leaving meeting")

        let meeting = Meeting(code: viewModel.meetingCode, leaveDate: Date())
        loudestMemberTimer?.invalidate()
        loudestMemberTimer = nil

        viewModel.leaveMeeting()

        coordinator?.meetingFinished(meeting, withReason: reason)
    }

    // MARK: - Private methods

    // MARK: - Configuration
    private func configureView() {
        contentView.configure(displayName: viewModel.displayName)
        contentView.setCamera(visible: viewModel.isCameraEnabled)
        contentView.setCameraControlButton(active: viewModel.isCameraEnabled)
        contentView.setMicrophoneMuteIcon(visible: viewModel.isMicrophoneEnabled == false)
        contentView.setMicrophoneControlButton(active: viewModel.isMicrophoneEnabled)
    }

    private func configurePageController() {
        addChild(pageController)
        contentView.setPageView(pageController.view)
        pageController.didMove(toParent: self)

        for case let page as PageContainerMember in pageController.controllers {
            contentView.addTopControl(for: page)
        }
    }

    // MARK: - Other functionality

    private func openMenu() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "Switch camera", style: .default) { [weak self] _ in
            self?.viewModel.flipCamera()
        })
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(actionSheet, animated: true)
    }
}

// MARK: - ActiveMeetingViewDelegate
extension ActiveMeetingViewController: ActiveMeetingViewDelegate {
    func activeMeetingView(_ view: ActiveMeetingView, didChangeCameraState enabled: Bool) {
        viewModel.setCamera(enabled: enabled)
    }

    func activeMeetingView(_ view: ActiveMeetingView, didChangeMicrophoneState enabled: Bool) {
        viewModel.setMicrophone(enabled: enabled)
    }

    func activeMeetingView(_ view: ActiveMeetingView, didScrollTillSectionWithIndex index: Int) {
        pageController.selectTab(index, withAnimation: false)
    }

    func activeMeetingViewDidTapMenuButton(_ view: ActiveMeetingView) {
        openMenu()
    }

    func activeMeetingViewDidTapLeaveMeetingButton(_ view: ActiveMeetingView) {
        leaveRoom(withReason: nil)
    }
}

// MARK: - ActiveMeetingViewModelDelegate
extension ActiveMeetingViewController: ActiveMeetingViewModelDelegate {
    func activeMeetingViewModel(_ viewModel: ViewModel, selfMemberDidChangeCameraState enabled: Bool) {
        contentView.setCameraControlButton(active: enabled)
    }

    func activeMeetingViewModel(_ viewModel: ViewModel, selfMemberDidChangeMicrophoneState enabled: Bool) {
        contentView.setMicrophoneControlButton(active: enabled)
    }

    func activeMeetingViewModel(_ viewModel: ViewModel, focusMemberDidChangeCameraState enabled: Bool) {
        contentView.setCamera(visible: enabled)
    }

    func activeMeetingViewModel(_ viewModel: ViewModel, focusMemberDidChangeMicrophoneState enabled: Bool) {
        contentView.setMicrophoneMuteIcon(visible: enabled == false)
    }

    func activeMeetingViewModel(_ viewModel: ViewModel, focusMemberDidChange member: PhenixCore.Member) {
        contentView.setCamera(placeholder: member.name)
        contentView.setCamera(visible: member.isVideoEnabled)
        contentView.setMicrophoneMuteIcon(visible: member.isAudioEnabled == false)

        viewModel.focus(member, on: contentView.getMainPreviewLayer())
    }
}
