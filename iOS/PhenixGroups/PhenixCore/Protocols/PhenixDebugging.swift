//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import PhenixSdk

public protocol PhenixDebugging: AnyObject {
    var phenixPCast: PhenixPCast { get }
}

extension PhenixManager: PhenixDebugging {
    public var phenixPCast: PhenixPCast { roomExpress.pcastExpress.pcast }
}
