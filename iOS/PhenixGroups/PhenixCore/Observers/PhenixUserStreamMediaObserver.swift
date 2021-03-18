//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

public protocol PhenixUserStreamMediaObserver: AnyObject {
    func userStreamMediaControllerDidChange(_ controller: UserMediaStreamController)
}

// MARK: - User stream media controller observation
public extension PhenixManager {
    func addUserStreamMediaControllerObserver(_ observer: PhenixUserStreamMediaObserver) {
        queue.async { [weak self] in
            let id = ObjectIdentifier(observer)
            self?.userStreamMediaObservations[id] = UserStreamMediaObserver(observer: observer)
        }
    }

    func removeUserStreamMediaControllerObserver(_ observer: PhenixUserStreamMediaObserver) {
        queue.async { [weak self] in
            let id = ObjectIdentifier(observer)
            self?.userStreamMediaObservations.removeValue(forKey: id)
        }
    }
}

internal extension PhenixManager {
    struct UserStreamMediaObserver {
        weak var observer: PhenixUserStreamMediaObserver?
    }

    func userStreamMediaControllerDidChange(_ controller: UserMediaStreamController) {
        dispatchPrecondition(condition: .onQueue(queue))

        for (id, observation) in userStreamMediaObservations {
            // If the observer is no longer in memory, we can clean up the observation for its ID
            guard let observer = observation.observer else {
                userStreamMediaObservations.removeValue(forKey: id)
                continue
            }

            observer.userStreamMediaControllerDidChange(controller)
        }
    }
}
