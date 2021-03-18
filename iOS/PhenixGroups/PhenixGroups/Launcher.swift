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

        let unrecoverableErrorCompletion: (String?) -> Void = { description in
            DispatchQueue.main.async {
                AppDelegate.terminate(
                    afterDisplayingAlertWithTitle: "Something went wrong!",
                    message: "Application entered in unrecoverable state and will be terminated (\(description ?? "N/A"))."
                )
            }
        }

        let mediaCreationTimeoutCompletion: () -> Void = {
            // Setting a delay to prevent a race condition with the
            // transition animation on the navigation controller
            // when the coordinator tries to switch screens to the
            // new meeting screen after the app has launched.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                AppDelegate.present(
                    alertWithTitle: "Experiencing problems connecting to Phenix",
                    message: "Check your network status."
                )
            }
        }

        // Prepare all the necessary components on a background thread.
        DispatchQueue.global(qos: .userInitiated).async {
            // Keep a strong reference so that the Launcher would not be deallocated too quickly.

            // Configure necessary object instances
            os_log(.debug, log: .launcher, "Configure Phenix instance")

            let pcast = self.deeplink?.uri ?? PhenixConfiguration.pcast
            let backend = self.deeplink?.backend ?? PhenixConfiguration.backend
            let maxVideoMembers = self.deeplink?.maxVideoMembers ?? 6

            let manager = PhenixManager(backend: backend, pcast: pcast, maxVideoSubscriptions: maxVideoMembers)
            manager.start(
                unrecoverableErrorCompletion: unrecoverableErrorCompletion,
                mediaCreationTimeoutHandler: mediaCreationTimeoutCompletion
            )

            let preferences = Preferences()

            // Create dependencies
            os_log(.debug, log: .launcher, "Create Dependency container")
            let container = DependencyContainer(phenixManager: manager, preferences: preferences)

            os_log(.debug, log: .launcher, "Start main coordinator")
            let coordinator = MainCoordinator(navigationController: nc, dependencyContainer: container)
            coordinator.initialMeetingCode = self.deeplink?.alias

            DispatchQueue.main.async {
                coordinator.start()
                completion(coordinator)
            }
        }
    }
}
