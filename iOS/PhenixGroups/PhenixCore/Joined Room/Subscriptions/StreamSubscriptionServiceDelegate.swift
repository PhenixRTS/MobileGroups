//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import PhenixSdk

protocol StreamSubscriptionServiceDelegate: AnyObject {
    func subscriptionServiceCanSubscribeForVideo(_ service: StreamSubscriptionService) -> Bool
    func subscriptionService(
        _ service: StreamSubscriptionService,
        shouldSubscribeTo stream: PhenixStream
    ) -> StreamSubscriptionProcessAction

    func subscriptionService(
        _ service: StreamSubscriptionService,
        didSubscribeTo subscription: StreamSubscriptionService.Subscription
    )
    func subscriptionService(
        _ service: StreamSubscriptionService,
        didReceiveDataFrom subscriptions: [StreamSubscriptionService.Subscription]
    )
}
