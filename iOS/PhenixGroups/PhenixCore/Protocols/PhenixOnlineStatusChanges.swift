//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

public protocol PhenixOnlineStatusChanges: AnyObject {
    func addOnlineStatusObserver(_ observer: PhenixOnlineStatusObserver)
    func removeOnlineStatusObserver(_ observer: PhenixOnlineStatusObserver)
}
