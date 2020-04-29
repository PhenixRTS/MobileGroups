//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

struct Launcher {
    // swiftlint:disable force_unwrapping
    private let url = URL(string: "https://demo.phenixrts.com/pcast")!
    private weak var window: UIWindow?

    init(window: UIWindow) {
        self.window = window
    }

    /// Starts all necessary application processes
    /// - Returns: Main coordinator which reference must  be saved
    func start() -> MainCoordinator {
        os_log(.debug, log: .launcher, "Launcher started")
        defer {
            os_log(.debug, log: .launcher, "Launcher finished")
        }

        // Create navigation controller
        let nc = UINavigationController()
        nc.navigationBar.isTranslucent = false

        configureAppWindow(with: nc)

        // Configure necessary object instances
        os_log(.debug, log: .launcher, "Configure Phenix instance")
        let manager = PhenixManager(backend: url)
        manager.start { [weak nc] description in
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

        let preferences = Preferences()

        // Create dependencies
        os_log(.debug, log: .launcher, "Create Dependency container")
        let container = DependencyContainer(phenixManager: manager, preferences: preferences)

        os_log(.debug, log: .launcher, "Start main coodinator")
        let coordinator = MainCoordinator(navigationController: nc, dependencyContainer: container)
        coordinator.start()

        return coordinator
    }

    func configureAppWindow(with nc: UINavigationController) {
        window?.rootViewController = nc
        window?.makeKeyAndVisible()
    }
}
