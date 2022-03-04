//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore

extension PhenixCore.Member {
    var isConnected: Bool { connectionState == .active || connectionState == .away }
}
