//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

public protocol RoomMemberAudioLevelObserver: AnyObject {
    func roomMember(_ member: RoomMember, didChange audioLevel: Double)
}

// MARK: - Audio observation
public extension RoomMember {
    func addAudioLevelObserver(_ observer: RoomMemberAudioLevelObserver) {
        queue.async { [weak self] in
            let id = ObjectIdentifier(observer)
            self?.audioLevelObservations[id] = AudioLevelObservation(observer: observer)
        }
    }

    func removeAudioLevelObserver(_ observer: RoomMemberAudioLevelObserver) {
        queue.async { [weak self] in
            let id = ObjectIdentifier(observer)
            self?.audioLevelObservations.removeValue(forKey: id)
        }
    }
}

internal extension RoomMember {
    struct AudioLevelObservation {
        weak var observer: RoomMemberAudioLevelObserver?
    }

    func audioLevelDidChange(_ audioLevel: Double) {
        dispatchPrecondition(condition: .onQueue(queue))

        for (id, observation) in audioLevelObservations {
            // If the observer is no longer in memory, we can clean up the observation for its ID
            guard let observer = observation.observer else {
                audioLevelObservations.removeValue(forKey: id)
                continue
            }

            observer.roomMember(self, didChange: audioLevel)
        }
    }
}
