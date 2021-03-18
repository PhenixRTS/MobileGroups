//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import PhenixSdk

struct RoomMemberStreamSubscription {
    let subscriptionType: SubscriptionType
    let subscriber: PhenixExpressSubscriber
    let renderer: PhenixRenderer
    let stream: PhenixStream

    static func options(for type: SubscriptionType) -> PhenixSubscribeToMemberStreamOptions {
        switch type {
        case .audio:
            return PhenixOptionBuilder.createSubscribeToMemberAudioStreamOptions()
        case .video:
            return PhenixOptionBuilder.createSubscribeToMemberVideoStreamOptions()
        }
    }
}

extension RoomMemberStreamSubscription {
    enum SubscriptionType: CustomStringConvertible {
        case audio, video

        var description: String {
            switch self {
            case .audio:
                return "audio"
            case .video:
                return "video"
            }
        }
    }
}

extension RoomMemberStreamSubscription: CustomStringConvertible {
    var description: String {
        "RoomMemberStreamSubscription(subscriptionType: \(subscriptionType), subscriber: \(subscriber), renderer: \(renderer), stream: \(stream))"
    }
}
