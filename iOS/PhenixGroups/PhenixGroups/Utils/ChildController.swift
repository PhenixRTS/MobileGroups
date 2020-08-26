//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

extension UIViewController {
    func add(_ child: UIViewController, into view: UIView) {
        add(child) { subview in
            view.addSubview(subview)
        }
    }

    func add(_ child: UIViewController, addViewHandler: (UIView) -> Void) {
        addChild(child)
        addViewHandler(child.view)
        child.didMove(toParent: self)
    }

    func remove() {
        guard parent != nil else {
            return
        }

        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}
