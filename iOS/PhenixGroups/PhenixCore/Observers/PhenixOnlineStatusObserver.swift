//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

public protocol PhenixOnlineStatusObserver: AnyObject {
    func phenixOnlineStatusDidChange(isOnline: Bool)
}

// MARK: - Phenix online status observation
public extension PhenixManager {
    func addOnlineStatusObserver(_ observer: PhenixOnlineStatusObserver) {
        queue.async { [weak self] in
            let id = ObjectIdentifier(observer)
            self?.onlineStatusObservations[id] = OnlineStatusObserver(observer: observer)
        }
    }

    func removeOnlineStatusObserver(_ observer: PhenixOnlineStatusObserver) {
        queue.async { [weak self] in
            let id = ObjectIdentifier(observer)
            self?.onlineStatusObservations.removeValue(forKey: id)
        }
    }
}

internal extension PhenixManager {
    struct OnlineStatusObserver {
        weak var observer: PhenixOnlineStatusObserver?
    }

    func onlineStatusDidChange(isOnline: Bool) {
        dispatchPrecondition(condition: .onQueue(queue))

        for (id, observation) in onlineStatusObservations {
            // If the observer is no longer in memory, we can clean up the observation for its ID
            guard let observer = observation.observer else {
                onlineStatusObservations.removeValue(forKey: id)
                continue
            }

            observer.phenixOnlineStatusDidChange(isOnline: isOnline)
        }
    }
}
