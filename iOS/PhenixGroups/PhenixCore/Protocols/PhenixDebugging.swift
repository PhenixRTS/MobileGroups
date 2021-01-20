//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import PhenixSdk

public protocol PhenixDebugging: AnyObject {
    var version: String? { get }
    var buildVersion: String? { get }
}

extension PhenixManager: PhenixDebugging {
    private var bundle: Bundle? {
        // Locate the PhenixSdk framework by its bundle identifier.
        Bundle(identifier: "com.phenixrts.framework")
    }

    /// Framework version
    public var version: String? { bundle?.appVersion }

    /// Framework build version
    public var buildVersion: String? { bundle?.appBuildVersion }
}
