//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

protocol Meeting: AnyObject {
    func showMeeting()
}

protocol MeetingFinished: AnyObject {
    func meetingFinished()
}

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

        navigationController.isNavigationBarHidden = true
        navigationController.pushViewController(vc, animated: false)
    }
}

extension MainCoordinator: Meeting {
    func showMeeting() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let vc = ActiveMeetingViewController.instantiate()
            vc.coordinator = self
            vc.phenix = self.dependencyContainer.phenixManager
            self.navigationController.pushViewController(vc, animated: true)
        }
    }
}

extension MainCoordinator: MeetingFinished {
    func meetingFinished() {
        DispatchQueue.main.async { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
    }
}
