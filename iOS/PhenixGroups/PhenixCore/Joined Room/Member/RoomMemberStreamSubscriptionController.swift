//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

protocol RoomMemberStreamSubscriptionDelegate: AnyObject {
    func streamSubscriptionController(_ controller: RoomMemberStreamSubscriptionController, canSubscribeTo streams: [PhenixStream]) -> Bool
    func streamSubscriptionController(_ controller: RoomMemberStreamSubscriptionController, didSubscribeWith subscription: RoomMemberStreamSubscription)
    func streamSubscriptionControllerDidDisposeSubscriptions(_ controller: RoomMemberStreamSubscriptionController)
}

class RoomMemberStreamSubscriptionController: RoomMemberDescription {
    private let queue: DispatchQueue
    private let roomExpress: PhenixRoomExpress
    private var streams: [PhenixStream] = []
    private var streamDisposable: PhenixDisposable?
    private var activeSubscriptions: [RoomMemberStreamSubscription]

    internal var desiredSubscriptionTypes: [RoomMemberStreamSubscription.SubscriptionType]
    internal weak var delegate: RoomMemberStreamSubscriptionDelegate?
    internal weak var memberRepresentation: RoomMemberRepresentation?
    internal weak var subscriptionTypeProvider: SubscriptionTypeProvider?

    init(roomExpress: PhenixRoomExpress, queue: DispatchQueue) {
        self.queue = queue
        self.roomExpress = roomExpress
        self.activeSubscriptions = []
        self.desiredSubscriptionTypes = []
    }

    func observeMemberStreams(_ member: PhenixMember) {
        queue.async { [weak self] in
            guard let self = self else { return }
            os_log(
                .debug,
                log: .roomMemberStreamSubscriptionController,
                "Observe stream changes, (%{PRIVATE}s), (%{PRIVATE}s)",
                self.memberDescription,
                self.description
            )
            self.streamDisposable = member
                .getObservableStreams()
                .subscribe(self.memberStreamDidChange)
        }
    }

    func dispose() {
        dispatchPrecondition(condition: .onQueue(queue))
        os_log(.debug, log: .roomMemberStreamSubscriptionController, "Dispose, (%{PRIVATE}s), (%{PRIVATE}s)", memberDescription, description)

        streamDisposable = nil
        activeSubscriptions.removeAll()
        desiredSubscriptionTypes.removeAll()
    }
}

// MARK: - CustomStringConvertible
extension RoomMemberStreamSubscriptionController: CustomStringConvertible {
    public var description: String {
        "RoomMemberStreamSubscriptionController(desired subscription types: \(desiredSubscriptionTypes), active subscriptions: \(activeSubscriptions))"
    }
}

// MARK: - Internal methods
internal extension RoomMemberStreamSubscriptionController {
    enum SubscriptionStatus {
        case subscribed(RoomMemberStreamSubscription)
        case failed(RoomMemberStreamSubscription.SubscriptionType)
    }

    func nextStream() -> PhenixStream? {
        dispatchPrecondition(condition: .onQueue(queue))

        if streams.isEmpty { return nil }
        return streams.removeFirst()
    }

    func process(_ streams: [PhenixStream]) {
        dispatchPrecondition(condition: .onQueue(queue))

        self.streams = streams

        // Retrieve next stream to which it would be possible to subscribe.
        guard let stream = nextStream() else {
            // There are no more stream so we can safely stop here.
            os_log(
                .debug,
                log: .roomMemberStreamSubscriptionController,
                "No streams available for subscription, (%{PRIVATE}s), (%{PRIVATE}s)",
                memberDescription,
                description
            )
            return
        }

        // Decide what subscriptions will be tried: audio or audio + video.
        // This information can be retrieved from the RoomMemberController
        // because it has access to all other current room members and can
        // say if the limit for video members have reached.

        let subscriptionTypes: [RoomMemberStreamSubscription.SubscriptionType] = {
            var types = [RoomMemberStreamSubscription.SubscriptionType]()
            types.append(.audio)

            if subscriptionTypeProvider?.canSubscribeWithVideo() ?? false {
                types.append(.video)
            }

            return types
        }()

        desiredSubscriptionTypes = subscriptionTypes

        // If the available stream will fail to provide subscription,
        // we need recursively try next stream from the stream list,
        // till we subscribe or there are no more streams left.
        var handler: ((SubscriptionStatus) -> Void)?

        handler = { [weak self] status in
            guard let self = self else { return }

            switch status {
            case .subscribed(let subscription):
                self.streams.removeAll()
                self.activeSubscriptions.append(subscription)
                self.delegate?.streamSubscriptionController(self, didSubscribeWith: subscription)

            case .failed(let type):
                if let stream = self.nextStream() {
                    self.subscribe(stream, for: type, then: handler)
                } else {
                    os_log(
                        .debug,
                        log: .roomMemberStreamSubscriptionController,
                        "No more streams available to subscribe for %{PRIVATE}s, (%{PRIVATE}s), (%{PRIVATE}s)",
                        String(describing: type),
                        self.memberDescription,
                        self.description
                    )
                    // Remove all desired subscription types to free
                    // up the space for other member to become an
                    // audio + video subscriber.
                    self.desiredSubscriptionTypes.removeAll()
                }
            }
        }

        for type in subscriptionTypes {
            subscribe(stream, for: type, then: handler)
        }
    }
}

// MARK: - Observable callback methods
internal extension RoomMemberStreamSubscriptionController {
    func memberStreamDidChange(_ changes: PhenixObservableChange<NSArray>?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard let streams = changes?.value as? [PhenixStream] else { return }

            guard self.delegate?.streamSubscriptionController(self, canSubscribeTo: streams) == true else { return }

            self.streams.removeAll()
            self.activeSubscriptions.removeAll()
            self.desiredSubscriptionTypes.removeAll()

            self.delegate?.streamSubscriptionControllerDidDisposeSubscriptions(self)

            os_log(.debug, log: .roomMemberStreamSubscriptionController, "Stream changed, (%{PRIVATE}s), (%{PRIVATE}s)", self.memberDescription, self.description)

            self.process(streams)
        }
    }
}

// MARK: - Private methods
private extension RoomMemberStreamSubscriptionController {
    func subscribe(_ stream: PhenixStream, for type: RoomMemberStreamSubscription.SubscriptionType, then handler: ((SubscriptionStatus) -> Void)?) {
        dispatchPrecondition(condition: .onQueue(queue))

        let options = RoomMemberStreamSubscription.options(for: type)

        let provider = MemberStreamSubscriptionProvider(
            roomExpress: roomExpress,
            stream: stream,
            options: options
        )

        os_log(.debug, log: .roomMemberStreamSubscriptionController, "Initiate subscription for: %{PRIVATE}s, (%{PRIVATE}s), (%{PRIVATE}s)", String(describing: type), memberDescription, description)

        provider.subscribe { [weak self] result in // swiftlint:disable:this closure_body_length
            guard let self = self else { return }
            self.queue.async { // swiftlint:disable:this closure_body_length
                switch result {
                case .success(let subscriptionResult):
                    os_log(
                        .debug,
                        log: .roomMemberStreamSubscriptionController,
                        "Subscription succeeded for %{PRIVATE}s, (%{PRIVATE}s), (%{PRIVATE}s)",
                        String(describing: type),
                        self.memberDescription,
                        self.description
                    )

                    let subscription = RoomMemberStreamSubscription(
                        subscriptionType: type,
                        subscriber: subscriptionResult.subscriber,
                        renderer: subscriptionResult.renderer,
                        stream: stream
                    )

                    handler?(.subscribed(subscription))

                case .failure(let error):
                    os_log(
                        .debug,
                        log: .roomMemberStreamSubscriptionController,
                        "Subscription failed for %{PRIVATE}s, reason: %{PRIVATE}s, (%{PRIVATE}s), (%{PRIVATE}s)",
                        String(describing: type),
                        error.localizedDescription,
                        self.memberDescription,
                        self.description
                    )

                    handler?(.failed(type))
                }
            }
        }
    }
}
