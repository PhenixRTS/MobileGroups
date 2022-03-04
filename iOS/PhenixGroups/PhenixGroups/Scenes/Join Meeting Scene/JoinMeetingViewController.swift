//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

class JoinMeetingViewController: UIViewController, Storyboarded {
    private static let logger = OSLog(identifier: "JoinMeetingViewController")

    // swiftlint:disable:next force_cast
    private var contentView: JoinMeetingView { view as! JoinMeetingView }
    weak var coordinator: (ShowMeeting & JoinCancellation)?

    var viewModel: ViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(viewModel != nil, "ViewModel should exist!")

        isModalInPresentation = true

        viewModel.delegate = self
        viewModel.subscribeToEvents()

        configure()
    }

    // MARK: - Private methods

    private func configure() {
        contentView.joinMeetingHandler = { [weak self] code in
            guard let self = self else { return }
            self.viewModel.join(meetingCode: code)
        }

        contentView.closeHandler = { [weak self] in
            guard let self = self else { return }
            self.coordinator?.cancel(self)
        }
    }
}

extension JoinMeetingViewController: JoinMeetingViewModelDelegate {
    func joinMeetingViewModel(_ view: ViewModel, willJoinMeeting meetingCode: String) {
        presentActivityIndicator()
    }

    func joinMeetingViewModel(_ view: ViewModel, didJoinMeeting meetingCode: String) {
        os_log(.debug, log: Self.logger, "Meeting joined, alias: %{public}s", meetingCode)
        dismissActivityIndicator {
            self.coordinator?.showMeeting()
        }
    }

    func joinMeetingViewModel(_ view: ViewModel, didFailToJoinMeetingWith description: String?) {
        os_log(.debug, log: Self.logger, "Failed to join meeting: %{public}s", description ?? "n/a")
        dismissActivityIndicator {
            AppDelegate.present(alertWithTitle: "Failed to join a meeting.", message: description)
        }
    }
}
