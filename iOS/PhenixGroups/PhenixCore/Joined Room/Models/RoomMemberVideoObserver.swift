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
        let id = ObjectIdentifier(observer)
        videoObservations[id] = VideoObservation(observer: observer)
    }

    func removeVideoObserver(_ observer: RoomMemberVideoObserver) {
        let id = ObjectIdentifier(observer)
        videoObservations.removeValue(forKey: id)
    }
}

internal extension RoomMember {
    struct VideoObservation {
        weak var observer: RoomMemberVideoObserver?
    }

    func videoStateDidChange(enabled: Bool) {
        for (id, observation) in videoObservations {
            // If the observer is no longer in memory, we can clean up the observation for its ID
            guard let observer = observation.observer else {
                audioObservations.removeValue(forKey: id)
                continue
            }

            observer.roomMemberVideoStateDidChange(self, enabled: enabled)
        }
    }
}
