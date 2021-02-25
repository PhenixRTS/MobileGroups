//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import PhenixDebug
import UIKit

class MainCoordinator: Coordinator {
    let navigationController: UINavigationController
    private(set) var childCoordinators = [Coordinator]()
    private let dependencyContainer: DependencyContainer
    private let device: UIDevice

    private var preferences: Preferences { dependencyContainer.preferences }
    private var phenixManager: PhenixManager { dependencyContainer.phenixManager }

    var phenixBackend: URL { phenixManager.backend }
    var phenixPcast: URL? { phenixManager.pcast }
    var phenixMaxVideoSubscriptions: Int { phenixManager.maxVideoSubscriptions }

    /// If provided before `start()` is executed, will automatically join provided meeting code
    var initialMeetingCode: String?

    init(navigationController: UINavigationController, dependencyContainer: DependencyContainer, device: UIDevice = .current) {
        self.navigationController = navigationController
        self.dependencyContainer = dependencyContainer
        self.device = device
    }

    func start() {
        os_log(.debug, log: .coordinator, "Start main coordinator")

        let vc = setupNewMeetingScene(withInitialMeetingCode: initialMeetingCode)

        UIView.transition(with: navigationController.view) {
            self.navigationController.setViewControllers([vc], animated: false)
        }
    }

    func join(meetingCode: String) {
        os_log(.debug, log: .coordinator, "Restart main coordinator")

        let nmvc = navigationController.viewControllers
            .compactMap { $0 as? NewMeetingViewController }
            .first

        nmvc?.initialMeetingCode = meetingCode

        if let amvc = navigationController.topViewController as? ActiveMeetingViewController {
            amvc.leaveRoom()
        }

        self.navigationController.topViewController?.presentedViewController?.dismiss(animated: false)

        if let vc = navigationController.topViewController as? NewMeetingViewController {
            vc.publishInitialMeetingIfNeeded()
        } else {
            UIView.transition(with: navigationController.view) {
                self.navigationController.popToRootViewController(animated: false)
            }
        }
    }
}

private extension MainCoordinator {
    func setupNewMeetingScene(withInitialMeetingCode meetingCode: String? = nil) -> NewMeetingViewController {
        if preferences.displayName == nil {
            preferences.displayName = device.name
        }

        let vc = NewMeetingViewController.instantiate()
        vc.coordinator = self
        vc.phenix = phenixManager
        vc.media = phenixManager.userMediaStreamController
        vc.preferences = preferences
        vc.initialMeetingCode = meetingCode

        let hvc = MeetingHistoryTableViewController.instantiate()
        vc.historyController = hvc
        hvc.delegate = vc
        hvc.viewDelegate = vc.newMeetingView
        hvc.loadMeetingsHandler = { [weak self] in
            self?.preferences.meetings.sorted { $0.leaveDate > $1.leaveDate } ?? []
        }

        return vc
    }

    func moveToMeeting(_ joinedRoom: JoinedRoom) {
        if navigationController.presentedViewController is JoinMeetingViewController {
            navigationController.presentedViewController?.dismiss(animated: true)
        }

        let vc = ActiveMeetingViewController.instantiate()
        vc.coordinator = self
        vc.displayName = preferences.displayName
        vc.media = phenixManager.userMediaStreamController
        vc.joinedRoom = joinedRoom

        UIView.transition(with: navigationController.view) {
            self.navigationController.pushViewController(vc, animated: false)
        }
    }

    func refreshMeeting(_ joinedRoom: JoinedRoom) {
        guard let controller = navigationController.visibleViewController as? ActiveMeetingViewController else {
            fatalError("Visible view controller is not ActiveMeetingViewController")
        }

        controller.joinedRoom = joinedRoom
        controller.configureRoom()
    }
}

extension MainCoordinator: ShowMeeting {
    func showMeeting(_ joinedRoom: JoinedRoom) {
        if navigationController.visibleViewController is ActiveMeetingViewController {
            refreshMeeting(joinedRoom)
        } else {
            moveToMeeting(joinedRoom)
        }
    }
}

extension MainCoordinator: JoinMeeting {
    func joinMeeting(displayName: String) {
        let vc = JoinMeetingViewController.instantiate()
        vc.coordinator = self
        vc.phenix = self.phenixManager
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
        var meetings = preferences.meetings

        if let savedMeetingIndex = meetings.firstIndex(where: { $0.code == meeting.code }) {
            // It was previously created meeting and user re-joined it.
            meetings.remove(at: savedMeetingIndex)
        }

        meetings.append(meeting)
        preferences.meetings = meetings

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            UIView.transition(with: self.navigationController.view) {
                self.navigationController.popViewController(animated: false)
            }
        }
    }
}

extension MainCoordinator: ShowDebugMenu {
    func showDebugMenu() {
        let viewModel = PhenixDebugViewModel(pcast: phenixManager.phenixPCast)
        let vc = PhenixDebugViewController(viewModel: viewModel)
        navigationController.present(vc, animated: true)
    }
}

fileprivate extension UIView {
    class func transition(with view: UIView, duration: TimeInterval = 0.25, options: UIView.AnimationOptions = [.transitionCrossDissolve], animations: (() -> Void)?) {
        UIView.transition(with: view, duration: duration, options: options, animations: animations, completion: nil)
    }
}
