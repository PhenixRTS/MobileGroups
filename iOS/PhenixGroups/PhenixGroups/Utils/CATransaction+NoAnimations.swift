//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import QuartzCore.CoreAnimation

internal extension CATransaction {
    /// Execute code without triggering the implicit animations
    /// - Parameter handler: Provided code to execute synchronously
    static func withoutAnimations(handler: () -> Void) {
        begin()
        setDisableActions(true)
        handler()
        commit()
    }
}
