//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

public protocol PhenixRoomLeaving: AnyObject {
    /// Leave currently joined room
    func leaveRoom()
}

extension PhenixManager: PhenixRoomLeaving {
    public func leaveRoom() {
        privateQueue.async { [weak self] in
            os_log(.debug, log: .phenixManager, "Leaving active room")
            self?.joinedRoomService = nil
        }
    }
}
