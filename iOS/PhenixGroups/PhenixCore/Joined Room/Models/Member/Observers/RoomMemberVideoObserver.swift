//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

public protocol RoomMemberVideoObserver: AnyObject {
    func roomMemberVideoStateDidChange(_ member: RoomMember, enabled: Bool)
}

// MARK: - Video observation
public extension RoomMember {
    func addVideoObserver(_ observer: RoomMemberVideoObserver) {
        queue.async { [weak self] in
            let id = ObjectIdentifier(observer)
            self?.videoObservations[id] = VideoObservation(observer: observer)
        }
    }

    func removeVideoObserver(_ observer: RoomMemberVideoObserver) {
        queue.async { [weak self] in
            let id = ObjectIdentifier(observer)
            self?.videoObservations.removeValue(forKey: id)
        }
    }
}

internal extension RoomMember {
    struct VideoObservation {
        weak var observer: RoomMemberVideoObserver?
    }

    func videoStateDidChange(enabled: Bool) {
        dispatchPrecondition(condition: .onQueue(queue))

        for (id, observation) in videoObservations {
            // If the observer is no longer in memory, we can clean up the observation for its ID
            guard let observer = observation.observer else {
                videoObservations.removeValue(forKey: id)
                continue
            }

            observer.roomMemberVideoStateDidChange(self, enabled: enabled)
        }
    }
}
