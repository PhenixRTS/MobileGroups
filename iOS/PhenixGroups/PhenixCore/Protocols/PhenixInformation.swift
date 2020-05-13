//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

public protocol PhenixInformation {
    var backendUri: URL { get }
}

extension PhenixManager: PhenixInformation {
    public var backendUri: URL { backend }
}
