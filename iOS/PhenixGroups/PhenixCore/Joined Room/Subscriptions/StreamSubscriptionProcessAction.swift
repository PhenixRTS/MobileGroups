//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

enum StreamSubscriptionProcessAction {
    /// Allow the service to continue with the stream subscription process for the current stream
    case `continue`
    /// Cancel the stream subscription process for the current stream and try next stream if possible.
    case cancel
    /// Cancels the whole stream subscription process not only for current stream, but for all next possible streams.
    case exit
}
