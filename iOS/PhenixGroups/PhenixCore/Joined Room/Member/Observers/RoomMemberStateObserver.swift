//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

public protocol RoomMemberStateObserver: AnyObject {
    func roomMember(_ member: RoomMember, didChange state: RoomMember.State)
}

// MARK: - Video observation
public extension RoomMember {
    func addStateObserver(_ observer: RoomMemberStateObserver) {
        let id = ObjectIdentifier(observer)
        self.stateObservations[id] = StateObservation(observer: observer)
    }

    func removeStateObserver(_ observer: RoomMemberStateObserver) {
        let id = ObjectIdentifier(observer)
        self.stateObservations.removeValue(forKey: id)
    }
}

internal extension RoomMember {
    struct StateObservation {
        weak var observer: RoomMemberStateObserver?
    }

    func stateDidChange(_ state: State) {
        dispatchPrecondition(condition: .onQueue(queue))

        for (id, observation) in stateObservations {
            // If the observer is no longer in memory, we can clean up the observation for its ID
            guard let observer = observation.observer else {
                stateObservations.removeValue(forKey: id)
                continue
            }

            observer.roomMember(self, didChange: state)
        }
    }
}
