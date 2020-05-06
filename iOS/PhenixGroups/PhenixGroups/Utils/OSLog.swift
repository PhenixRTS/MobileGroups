//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log

extension OSLog {
    // swiftlint:disable force_unwrapping
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs the view cycles like viewDidLoad.
    static let viewcycle = OSLog(subsystem: subsystem, category: "Phenix.App.ViewCycle")

    // MARK: - Application components
    static let coordinator = OSLog(subsystem: subsystem, category: "Phenix.App.Coordinator")
    static let launcher = OSLog(subsystem: subsystem, category: "Phenix.App.Launcher")
    static let newMeetingScene = OSLog(subsystem: subsystem, category: "Phenix.App.Scene.NewMeeting")
    static let joinMeetingScene = OSLog(subsystem: subsystem, category: "Phenix.App.Scene.JoinMeeting")
    static let activeMeetingScene = OSLog(subsystem: subsystem, category: "Phenix.App.Scene.ActiveMeeting")
}
