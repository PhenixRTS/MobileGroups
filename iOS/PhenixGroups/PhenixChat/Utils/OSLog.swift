//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log

extension OSLog {
    // swiftlint:disable force_unwrapping
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs the main Phenix manager
    static let chatService = OSLog(subsystem: subsystem, category: "Phenix.Chat.ChatService")
}
