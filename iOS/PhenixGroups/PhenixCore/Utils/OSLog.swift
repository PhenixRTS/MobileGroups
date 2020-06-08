//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log

extension OSLog {
    // swiftlint:disable force_unwrapping
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs the main Phenix manager
    static let phenixManager = OSLog(subsystem: subsystem, category: "Phenix.Core.PhenixManager")
    static let joinedRoom = OSLog(subsystem: subsystem, category: "Phenix.Core.JoinedRoom")
    static let roomMember = OSLog(subsystem: subsystem, category: "Phenix.Core.RoomMember")
}
