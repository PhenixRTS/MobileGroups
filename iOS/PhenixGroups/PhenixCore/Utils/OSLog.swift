//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
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
    static let mediaController = OSLog(subsystem: subsystem, category: "Phenix.Core.MediaController")
    static let memberController = OSLog(subsystem: subsystem, category: "Phenix.Core.MemberController")
    static let roomMemberMediaController = OSLog(subsystem: subsystem, category: "Phenix.Core.RoomMemberMediaController")
    static let roomMemberStreamSubscriptionController = OSLog(subsystem: subsystem, category: "Phenix.Core.RoomMemberStreamSubscriptionController")
    static let roomMemberStreamAudioLevelProvider = OSLog(subsystem: subsystem, category: "Phenix.Core.RoomMemberStreamAudioLevelProvider")
    static let roomMemberStreamAudioStateProvider = OSLog(subsystem: subsystem, category: "Phenix.Core.RoomMemberStreamAudioStateProvider")
    static let roomMemberStreamVideoStateProvider = OSLog(subsystem: subsystem, category: "Phenix.Core.RoomMemberStreamVideoStateProvider")
}
