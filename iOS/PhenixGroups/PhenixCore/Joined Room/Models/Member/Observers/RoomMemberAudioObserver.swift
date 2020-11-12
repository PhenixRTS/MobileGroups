//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

public protocol RoomMemberAudioObserver: AnyObject {
    func roomMemberAudioStateDidChange(_ member: RoomMember, enabled: Bool)
}

// MARK: - Audio observation
public extension RoomMember {
    func addAudioObserver(_ observer: RoomMemberAudioObserver) {
        let id = ObjectIdentifier(observer)
        audioObservations[id] = AudioObservation(observer: observer)
    }

    func removeAudioObserver(_ observer: RoomMemberAudioObserver) {
        let id = ObjectIdentifier(observer)
        audioObservations.removeValue(forKey: id)
    }
}

internal extension RoomMember {
    struct AudioObservation {
        weak var observer: RoomMemberAudioObserver?
    }

    func audioStateDidChange(enabled: Bool) {
        for (id, observation) in audioObservations {
            // If the observer is no longer in memory, we can clean up the observation for its ID
            guard let observer = observation.observer else {
                audioObservations.removeValue(forKey: id)
                continue
            }

            observer.roomMemberAudioStateDidChange(self, enabled: enabled)
        }
    }
}