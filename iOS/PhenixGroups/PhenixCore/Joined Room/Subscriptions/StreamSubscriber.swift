//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

protocol SubscriberDelegate: AnyObject {
    func subscriber(
        _ subscriber: StreamSubscriptionService.Subscriber,
        didSubscribeWith subscription: StreamSubscriptionService.Subscription
    )
    func subscriber(
        _ subscriber: StreamSubscriptionService.Subscriber,
        didFailToSubscribeTo stream: PhenixStream,
        with kind: StreamSubscriptionService.Subscription.Kind
    )
}

extension StreamSubscriptionService {
    class Subscriber {
        private let id = UUID()
        private let roomExpress: PhenixRoomExpress
        private let stream: PhenixStream
        private var subscription: Subscription?

        let kind: Subscription.Kind
        weak var delegate: SubscriberDelegate?
        var delegateQueue: DispatchQueue = .main

        init(roomExpress: PhenixRoomExpress, stream: PhenixStream, kind: Subscription.Kind) {
            self.roomExpress = roomExpress
            self.stream = stream
            self.kind = kind
        }

        func subscribe() {
            let options: PhenixSubscribeToMemberStreamOptions

            // Create a potential subscription instance,
            // so that it would be possible to link this
            // subscription with the stream monitor,
            // to receive a callback when the stream
            // ends.
            subscription = Subscription(stream: stream, kind: kind)

            switch kind {
            case .audio:
                options = PhenixOptionBuilder.createSubscribeToMemberAudioStreamOptions { [weak subscription] reason in
                    subscription?.streamDidEnd(with: reason)
                }
            case .video:
                options = PhenixOptionBuilder.createSubscribeToMemberVideoStreamOptions { [weak subscription] reason in
                    subscription?.streamDidEnd(with: reason)
                }
            }

            roomExpress.subscribe(toMemberStream: stream, options) { [weak self] status, subscriber, _ in
                guard let self = self else { return }
                guard let subscription = self.subscription else { return }

                switch status {
                case .ok:
                    guard let subscriber = subscriber else {
                        fatalError("Subscriber is not provided.")
                    }

                    let renderer: PhenixRenderer = subscriber.createRenderer()
                    subscription.set(subscriber: subscriber, renderer: renderer)

                    self.delegateQueue.async {
                        self.delegate?.subscriber(self, didSubscribeWith: subscription)
                    }

                default:
                    self.delegateQueue.async {
                        self.delegate?.subscriber(self, didFailToSubscribeTo: self.stream, with: self.kind)
                    }
                }
            }
        }
    }
}

// MARK: - Disposable
extension StreamSubscriptionService.Subscriber {
    func dispose() {
        os_log(
            .debug,
            log: .streamSubscriber,
            "%{private}s, Dispose",
            description
        )

        delegate = nil
        subscription = nil
    }
}

// MARK: - CustomStringConvertible
extension StreamSubscriptionService.Subscriber: CustomStringConvertible {
    var description: String {
        "StreamSubscriptionService.Subscriber(stream: \(stream), kind: \(kind))"
    }
}

extension StreamSubscriptionService.Subscriber: Equatable {
    static func == (lhs: StreamSubscriptionService.Subscriber, rhs: StreamSubscriptionService.Subscriber) -> Bool {
        lhs.id == rhs.id
    }
}
