//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get }
    var navigationController: UINavigationController { get }

    func start()
}

extension Coordinator {
    func transition(animations: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
        UIView.transition(
            with: navigationController.view,
            duration: 0.25,
            options: [.transitionCrossDissolve],
            animations: animations,
            completion: completion
        )
    }
}
