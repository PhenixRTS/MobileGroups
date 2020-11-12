//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

public enum PhenixConfiguration {
    // swiftlint:disable force_unwrapping
    public static var backend = URL(string: "https://demo.phenixrts.com/pcast")!
    public static var pcast: URL?

    static let capabilities = ["ld", "multi-bitrate", "prefer-h264"]
}
