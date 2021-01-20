//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import PhenixSdk

public protocol PhenixLogs: AnyObject {
    func collectPCastLogs(then handle: @escaping (String?) -> Void)
}

extension PhenixManager: PhenixLogs {
    public func collectPCastLogs(then handle: @escaping (String?) -> Void) {
        let pcast = roomExpress.pcastExpress.pcast

        pcast?.collectLogMessages { _, status, messages in
            guard let messages = messages, status == .ok else {
                handle(nil)
                return
            }

            handle(messages)
        }
    }
}
