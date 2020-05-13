//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

class MainCoordinator: Coordinator {
    let navigationController: UINavigationController
    private(set) var childCoordinators = [Coordinator]()

    private let dependencyContainer: DependencyContainer

    init(navigationController: UINavigationController, dependencyContainer: DependencyContainer) {
        self.navigationController = navigationController
        self.dependencyContainer = dependencyContainer
    }

    func start() {
        os_log(.debug, log: .coordinator, "Main coordinator started")

        let vc = NewMeetingViewController.instantiate()
        vc.coordinator = self
        vc.phenix = dependencyContainer.phenixManager
        vc.preferences = dependencyContainer.preferences

        let hvc = MeetingHistoryTableViewController.instantiate()
        vc.historyController = hvc
        hvc.delegate = vc
        hvc.viewDelegate = vc.newMeetingView
        hvc.loadMeetings = { [weak self] in
            self?.dependencyContainer.preferences.meetings.sorted { $0.leaveDate > $1.leaveDate } ?? []
        }

        navigationController.isNavigationBarHidden = true
        navigationController.pushViewController(vc, animated: false)
    }
}

extension MainCoordinator: ShowMeeting {
    func showMeeting(code: String) {
        if navigationController.presentedViewController is JoinMeetingViewController {
            navigationController.presentedViewController?.dismiss(animated: true)
        }

        let vc = ActiveMeetingViewController.instantiate()
        vc.coordinator = self
        vc.phenix = dependencyContainer.phenixManager
        vc.code = code
        navigationController.pushViewController(vc, animated: true)
    }
}

extension MainCoordinator: JoinMeeting {
    func joinMeeting(displayName: String) {
        let vc = JoinMeetingViewController.instantiate()
        vc.coordinator = self
        vc.phenix = self.dependencyContainer.phenixManager
        vc.displayName = displayName
        navigationController.present(vc, animated: true)
    }
}

extension MainCoordinator: JoinCancellation {
    func cancel(_ vc: UIViewController) {
        vc.dismiss(animated: true)
    }
}

extension MainCoordinator: MeetingFinished {
    func meetingFinished(_ meeting: Meeting) {
        dependencyContainer.preferences.meetings.append(meeting)
        DispatchQueue.main.async { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
    }
}
