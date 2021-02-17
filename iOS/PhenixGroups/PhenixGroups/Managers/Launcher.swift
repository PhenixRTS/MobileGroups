//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

class Launcher {
    private let deeplink: PhenixDeeplinkModel?
    private weak var window: UIWindow?

    init(window: UIWindow, deeplink: PhenixDeeplinkModel? = nil) {
        self.window = window
        self.deeplink = deeplink
    }

    /// Starts all necessary application processes
    /// - Returns: Main coordinator which reference must  be saved
    func start(completion: @escaping (MainCoordinator) -> Void) {
        os_log(.debug, log: .launcher, "Launcher started")
        defer {
            os_log(.debug, log: .launcher, "Launcher finished")
        }

        // Create launch view controller, which will hide all async loading
        let vc = LaunchViewController.instantiate()

        // Create navigation controller
        let nc = UINavigationController(rootViewController: vc)
        nc.isNavigationBarHidden = true
        nc.navigationBar.isTranslucent = false

        // Display the navigation controller holding screen which looks the same as the launch screen.
        window?.rootViewController = nc
        window?.makeKeyAndVisible()

        let unrecoverableErrorCompletion: (String?) -> Void = { [weak nc] description in
            // Unrecoverable Error Completion
            let reason = description ?? "N/A"
            let alert = UIAlertController(title: "Error", message: "Phenix SDK reached unrecoverable error: (\(reason))", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(title: "Close app", style: .default) { _ in
                    fatalError("Unrecoverable error: \(String(describing: description))")
                }
            )

            nc?.presentedViewController?.dismiss(animated: false)
            nc?.present(alert, animated: true)
        }

        // Prepare all the necessary components on a background thread.
        DispatchQueue.global(qos: .userInitiated).async {
            // Keep a strong reference so that the Launcher would not be deallocated too quickly.

            // Configure necessary object instances
            os_log(.debug, log: .launcher, "Configure Phenix instance")

            let backend = self.deeplink?.backend ?? PhenixConfiguration.backend
            let pcast = self.deeplink?.uri ?? PhenixConfiguration.pcast
            let maxVideoMembers = self.deeplink?.maxVideoMembers ?? 12

            let manager = PhenixManager(backend: backend, pcast: pcast, maxVideoSubscriptions: maxVideoMembers)
            manager.start(unrecoverableErrorCompletion: unrecoverableErrorCompletion)

            let preferences = Preferences()

            // Create dependencies
            os_log(.debug, log: .launcher, "Create Dependency container")
            let container = DependencyContainer(phenixManager: manager, preferences: preferences)

            os_log(.debug, log: .launcher, "Start main coodinator")
            let coordinator = MainCoordinator(navigationController: nc, dependencyContainer: container)
            coordinator.initialMeetingCode = self.deeplink?.alias

            DispatchQueue.main.async {
                coordinator.start()
                completion(coordinator)
            }
        }
    }
}
