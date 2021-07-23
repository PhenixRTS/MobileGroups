//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

protocol SubscriptionDelegate: AnyObject {
    func subscription(
        _ subscription: StreamSubscriptionService.Subscription,
        didReceiveQuality status: PhenixDataQualityStatus
    )
    func subscription(
        _ subscription: StreamSubscriptionService.Subscription,
        streamDidEndWith reason: PhenixStreamEndedReason
    )
}

extension StreamSubscriptionService {
    class Subscription {
        let kind: Kind
        let stream: PhenixStream

        private(set) var renderer: PhenixRenderer!
        private(set) var subscriber: PhenixExpressSubscriber!
        private(set) var lastKnownDataQuality: PhenixDataQualityStatus?

        weak var delegate: SubscriptionDelegate?
        var delegateQueue: DispatchQueue = .main

        init(stream: PhenixStream, kind: Kind) {
            self.stream = stream
            self.kind = kind
        }

        init(stream: PhenixStream, subscriber: PhenixExpressSubscriber, renderer: PhenixRenderer, kind: Kind) {
            self.stream = stream
            self.renderer = renderer
            self.subscriber = subscriber
            self.kind = kind
        }

        /// Provide inner subscriber and renderer parameters, which could be initialized later, when the subscription instance is already created.
        /// - Parameters:
        ///   - subscriber: Inner PhenixSDK subscriber instance, which is returned by the SDK after a successful subscription.
        ///   - renderer: Inner PhenixSDK renderer instance.
        func set(subscriber: PhenixExpressSubscriber, renderer: PhenixRenderer) {
            guard self.subscriber == nil && self.renderer == nil else {
                fatalError("Subscriber and Renderer can be provided only once to a subscription object.")
            }

            self.subscriber = subscriber
            self.renderer = renderer
        }

        func observeDataQuality() {
            guard let renderer = renderer else {
                assertionFailure("Renderer should be provided, before starting to observe the data quality.")
                return
            }

            os_log(
                .debug,
                log: .streamSubscription,
                "%{private}s, Observe data quality changes",
                description
            )

            renderer.setDataQualityChangedCallback { [weak self] currentRenderer, status, reason in
                self?.qualityDidChange(currentRenderer, status, reason)
            }
        }

        func streamDidEnd(with reason: PhenixStreamEndedReason) {
            delegateQueue.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.subscription(self, streamDidEndWith: reason)
            }
        }

        private func qualityDidChange (
            _ renderer: PhenixRenderer?,
            _ status: PhenixDataQualityStatus,
            _ reason: PhenixDataQualityReason
        ) {
            lastKnownDataQuality = status

            delegateQueue.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.subscription(self, didReceiveQuality: status)
            }
        }
    }
}

// MARK: - Disposable
extension StreamSubscriptionService.Subscription {
    func dispose() {
        os_log(
            .debug,
            log: .streamSubscription,
            "%{private}s, Dispose",
            description
        )

        renderer?.stop()
        renderer?.setDataQualityChangedCallback(nil)
    }
}

// MARK: - CustomStringConvertible
extension StreamSubscriptionService.Subscription: CustomStringConvertible {
    var description: String {
        """
        StreamSubscriptionService.Subscription(\
        stream: \(String(describing: stream.getUri())), \
        kind: \(kind), \
        lastKnownDataQuality: \(String(describing: lastKnownDataQuality)))
        """
    }
}

// MARK: - CustomDebugStringConvertible
extension StreamSubscriptionService.Subscription: CustomDebugStringConvertible {
    var debugDescription: String {
        """
        StreamSubscriptionService.Subscription(\
        stream: \(String(describing: stream.getUri())), \
        renderer: \(String(describing: renderer)), \
        subscriber: \(String(describing: subscriber)), \
        kind: \(kind), \
        lastKnownDataQuality: \(String(describing: lastKnownDataQuality)))
        """
    }
}

// MARK: - StreamSubscriptionService.Subscription.Kind
extension StreamSubscriptionService.Subscription {
    enum Kind: CustomStringConvertible {
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
