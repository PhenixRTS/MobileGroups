//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import PhenixDeeplink
import UIKit

class MainCoordinator: Coordinator {
    private static let logger = OSLog(identifier: "ActiveMeetingViewController")

    private let core: PhenixCore
    private let session: AppSession
    private let preferences: Preferences

    private(set) var childCoordinators = [Coordinator]()

    let navigationController: UINavigationController

    /// If provided before `start()` is executed, will automatically join provided meeting code
    var initialMeetingCode: String?

    init(
        core: PhenixCore,
        session: AppSession,
        preferences: Preferences,
        navigationController: UINavigationController
    ) {
        self.core = core
        self.session = session
        self.preferences = preferences
        self.navigationController = navigationController
    }

    func start() {
        let viewController = setupNewMeetingScene(withInitialMeetingCode: session.meetingCode)

        transition {
            self.navigationController.setViewControllers([viewController], animated: false)
        }
    }

    func validateSessionConfiguration(deeplink model: PhenixDeeplinkModel) throws {
        try session.validate(model)
    }

    func join(meetingCode: String) {
        os_log(.debug, log: Self.logger, "Join a meeting")

        let viewControllers = navigationController.viewControllers.compactMap { $0 as? NewMeetingViewController }

        guard let viewController = viewControllers.first else {
            return
        }

        viewController.viewModel.initialMeetingCode = meetingCode

        if let activeMeetingViewController = navigationController.topViewController as? ActiveMeetingViewController {
            activeMeetingViewController.leaveRoom()
        }

        navigationController.topViewController?.presentedViewController?.dismiss(animated: false)

        if let viewController = navigationController.topViewController as? NewMeetingViewController {
            viewController.viewModel.joinMeetingIfNecessary()
        } else {
            transition {
                self.navigationController.popToRootViewController(animated: false)
                viewController.viewModel.joinMeetingIfNecessary()
            }
        }
    }
}

private extension MainCoordinator {
    func setupNewMeetingScene(withInitialMeetingCode meetingCode: String? = nil) -> NewMeetingViewController {
        let viewModel = NewMeetingViewController.ViewModel(core: core, session: session, preferences: preferences)
        viewModel.initialMeetingCode = meetingCode

        let viewController = NewMeetingViewController.instantiate()
        viewController.coordinator = self
        viewController.viewModel = viewModel

        let historyViewDataSource = MeetingHistoryTableViewController.DataSource(preferences: preferences)

        let historyViewController = MeetingHistoryTableViewController.instantiate()
        viewController.meetingHistoryViewController = historyViewController

        historyViewController.dataSource = historyViewDataSource
        historyViewController.delegate = viewController
        historyViewController.viewDelegate = viewController.view as? MeetingHistoryTableViewDelegate

        return viewController
    }

    func moveToMeeting() {
        if navigationController.presentedViewController is JoinMeetingViewController {
            navigationController.presentedViewController?.dismiss(animated: true)
        }

        os_log(.debug, log: Self.logger, "Move to joined room")

        let viewController = makeActiveMeetingViewController()
        viewController.coordinator = self

        transition {
            self.navigationController.pushViewController(viewController, animated: false)
        }
    }

    func makeActiveMeetingViewController() -> ActiveMeetingViewController {
        let chatViewController = makeActiveMeetingChatViewController()
        let memberListViewController = makeActiveMeetingMemberViewController()
        let infoViewController = makeActiveMeetingInformationViewController()

        let pageController = PageViewController()
        pageController.setControllers([memberListViewController, chatViewController, infoViewController])

        let viewModel = ActiveMeetingViewController.ViewModel(core: core, session: session, preferences: preferences)
        let viewController = ActiveMeetingViewController.instantiate()
        viewController.viewModel = viewModel
        viewController.pageController = pageController

        return viewController
    }

    func makeActiveMeetingChatViewController() -> ActiveMeetingChatViewController {
        let dataSource = ActiveMeetingChatViewController.DataSource(preferences: preferences)
        let viewModel = ActiveMeetingChatViewController.ViewModel(
            core: core,
            session: session,
            preferences: preferences
        )

        let viewController = ActiveMeetingChatViewController()
        viewController.viewModel = viewModel
        viewController.dataSource = dataSource

        return viewController
    }

    func makeActiveMeetingMemberViewController() -> ActiveMeetingMemberListViewController {
        let dataSource = ActiveMeetingMemberListViewController.DataSource(core: core)
        let viewModel = ActiveMeetingMemberListViewController.ViewModel(
            core: core,
            session: session
        )

        let viewController = ActiveMeetingMemberListViewController()
        viewController.viewModel = viewModel
        viewController.dataSource = dataSource

        return viewController
    }

    func makeActiveMeetingInformationViewController() -> ActiveMeetingInformationViewController {
        let viewModel = ActiveMeetingInformationViewController.ViewModel(session: session, preferences: preferences)
        let viewController = ActiveMeetingInformationViewController()
        viewController.viewModel = viewModel

        return viewController
    }
}

extension MainCoordinator: ShowMeeting {
    func showMeeting() {
        moveToMeeting()
    }
}

extension MainCoordinator: JoinMeeting {
    func showJoinMeeting() {
        let viewModel = JoinMeetingViewController.ViewModel(core: core, session: session, preferences: preferences)

        let viewController = JoinMeetingViewController.instantiate()
        viewController.coordinator = self
        viewController.viewModel = viewModel

        navigationController.present(viewController, animated: true)
    }
}

extension MainCoordinator: JoinCancellation {
    func cancel(_ viewController: UIViewController) {
        viewController.dismiss(animated: true) { [weak self] in
            if let meetingViewController = self?.navigationController.topViewController as? NewMeetingViewController {
                meetingViewController.subscribeForEvents()
            }
        }
    }
}

extension MainCoordinator: MeetingFinished {
    func meetingFinished(_ meeting: Meeting, withReason reason: (title: String, message: String?)?) {
        var meetings = preferences.meetings

        if let savedMeetingIndex = meetings.firstIndex(where: { $0.code == meeting.code }) {
            // It was previously created meeting and user re-joined it.
            meetings.remove(at: savedMeetingIndex)
        }

        meetings.append(meeting)
        preferences.meetings = meetings

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.transition {
                self.navigationController.popViewController(animated: false)
            } completion: { _ in
                if let reason = reason {
                    AppDelegate.present(alertWithTitle: reason.title, message: reason.message)
                }
            }
        }
    }
}
