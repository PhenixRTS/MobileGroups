//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

protocol ActivityIndicatorProvider {
    func presentActivityIndicator()
    func dismissActivityIndicator(then: (() -> Void)?)
}

extension UIViewController: ActivityIndicatorProvider {
    func presentActivityIndicator() {
        guard (presentedViewController is ActivityIndicatorController) == false else {
            return
        }

        let controller = ActivityIndicatorController()
        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .crossDissolve
        present(controller, animated: true)
    }

    func dismissActivityIndicator(then: (() -> Void)? = nil) {
        guard presentedViewController is ActivityIndicatorController else {
            then?()
            return
        }
        dismiss(animated: true, completion: then)
    }
}
