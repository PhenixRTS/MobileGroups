//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

struct Launcher {
    // swiftlint:disable force_unwrapping
    private let url = URL(string: "https://demo.phenixrts.com/pcast")!

    /// Starts all necessary application processes
    /// - Returns: Main coordinator which reference must  be saved
    func start() -> MainCoordinator {
        os_log(.debug, log: .launcher, "Launcher started")
        defer {
            os_log(.debug, log: .launcher, "Launcher finished")
        }

        // Configure necessary object instances
        os_log(.debug, log: .launcher, "Configure Phenix instance")
        let manager = PhenixManager(backend: url)
        manager.start()

        // Create dependencies
        os_log(.debug, log: .launcher, "Create Dependency container")
        let container = DependencyContainer(phenixManager: manager)

        // Create navigation controller
        let nc = UINavigationController()
        nc.navigationBar.isTranslucent = false

        os_log(.debug, log: .launcher, "Start main coodinator")
        let coordinator = MainCoordinator(navigationController: nc, dependencyContainer: container)
        coordinator.start()

        return coordinator
    }
}
