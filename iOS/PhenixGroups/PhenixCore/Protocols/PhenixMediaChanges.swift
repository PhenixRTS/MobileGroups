//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

public protocol PhenixMediaChanges: AnyObject {
    func addUserStreamMediaControllerObserver(_ observer: PhenixUserStreamMediaObserver)
    func removeUserStreamMediaControllerObserver(_ observer: PhenixUserStreamMediaObserver)
}
