//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

// swiftlint:disable file_length

import Foundation
import os.log
import PhenixSdk

class StreamSubscriptionService: RoomMemberDescription {
    private let subscriptionWaitTime: TimeInterval = 10
    private let roomExpress: PhenixRoomExpress

    /// All the currently observed streams.
    private var observedStreams: [PhenixStream] = []

    /// All the streams, which can be tried to subscribe.
    ///
    /// The list has been cleared from failure streams.
    private var candidateStreams: [PhenixStream] = []

    /// If the app fails to subscribe to a stream, stream URI gets saved into
    /// this failed stream list, so that in future the app would not retry to
    /// subscribe to it.
    private var failureStreamURIs: Set<PhenixStream.URI> = []

    /// Currently active subscribers, which are trying to subscribe to a provided stream.
    private(set) var subscribers: [Subscriber] = []

    /// Currently active subscriptions, which succeeded to subscribe to the stream.
    private(set) var subscriptions: [Subscription] = []
    private var subscriptionWatchdog: Watchdog?

    /// A stream, which is currently in process of subscription.
    private var streamInProcess: PhenixStream?

    private var observedStreamDisposable: PhenixDisposable?

    var queue: DispatchQueue = .main
    var delegateQueue: DispatchQueue = .main

    weak var delegate: StreamSubscriptionServiceDelegate?
    weak var memberRepresentation: RoomMemberRepresentation?

    init(roomExpress: PhenixRoomExpress) {
        self.roomExpress = roomExpress
    }

    func observeMemberStreams(_ member: PhenixMember) {
        observedStreamDisposable = member
            .getObservableStreams()
            .subscribe(self.memberStreamDidChange)
    }

    func subscribeNextCandidateStreamIfPossible() {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(
            .debug,
            log: .streamSubscriptionService,
            "%{private}s, Subscribe to next candidate stream, if possible",
            memberDescription
        )

        guard let stream = nextCandidateStream() else {
            os_log(
                .debug,
                log: .streamSubscriptionService,
                "%{private}s, No candidate stream available for subscription",
                memberDescription
            )

            return
        }

        subscribe(to: stream)
    }
}

// MARK: - Private methods
private extension StreamSubscriptionService {
    func nextCandidateStream() -> PhenixStream? {
        dispatchPrecondition(condition: .onQueue(queue))

        // Be sure that there is at least one
        // stream in the candidate stream list
        // from which to choose next stream.
        guard candidateStreams.isEmpty == false else {
            return nil
        }

        // Check, if there was a stream already
        // in process, if there was - then select
        // the next available stream, if not -
        // then provide back the last stream from
        // the candidate stream list.
        guard let currentStream = streamInProcess else {
            return candidateStreams.last
        }

        // In situations, when there is only a one stream
        // in the candidate list, and that stream already
        // was processed just now, we do not retry it.
        if candidateStreams.first?.getUri() == currentStream.getUri() && candidateStreams.count == 1 {
            return nil
        }

        // Search for the next stream index.
        // If the currently selected stream does not
        // exist in the candidate stream list, then
        // just return the last available stream.
        guard let currentStreamIndex = candidateStreams.firstIndex(where: { $0.getUri() == currentStream.getUri() }) else {
            return candidateStreams.last
        }

        // Retrieve next stream array index.
        let nextStreamIndex = candidateStreams.index(before: currentStreamIndex)

        // If we have reached the end of the candidate
        // stream list, or there are only one stream
        // in the list, then the next index will be
        // negative. In this case, we need to start
        // to go over the list once again.
        guard nextStreamIndex > 0 else {
            return candidateStreams.last
        }

        let nextStream = candidateStreams[nextStreamIndex]

        return nextStream
    }

    func exclude(_ unnecessaryStreams: [PhenixStream], from streams: [PhenixStream]) -> [PhenixStream] {
        let unnecessaryStreamURIs = unnecessaryStreams.compactMap { $0.getUri() }
        return exclude(unnecessaryStreamURIs, from: streams)
    }

    func exclude(_ unnecessaryStreamURIs: [String], from streams: [PhenixStream]) -> [PhenixStream] {
        streams.filter { stream in
            !unnecessaryStreamURIs.contains(stream.getUri())
        }
    }

    func subscribe(to stream: PhenixStream) {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(
            .debug,
            log: .streamSubscriptionService,
            "%{private}s, Try to subscribe to stream %{private}s",
            memberDescription,
            stream.getUri()
        )

        streamInProcess = stream

        let streamSubscriptionPermission = delegate?.subscriptionService(self, shouldSubscribeTo: stream) ?? .continue

        switch streamSubscriptionPermission {
        case .continue:
            // Process can continue to subscribe to the current stream.
            break

        case .cancel:
            os_log(
                .debug,
                log: .streamSubscriptionService,
                "%{private}s, Cancel subscription for stream %{private}s",
                memberDescription,
                stream.getUri()
            )

            subscribeNextCandidateStreamIfPossible()
            return

        case .exit:
            os_log(
                .debug,
                log: .streamSubscriptionService,
                "%{private}s, Exit subscription process",
                memberDescription,
                stream.getUri()
            )

            streamInProcess = nil
            return
        }

        disposeSubscriptionWatchdog()
        disposeSubscribers()
        disposeSubscriptions()

        var subscriptionKinds: [Subscription.Kind] = [.audio]
        if delegate?.subscriptionServiceCanSubscribeForVideo(self) == true {
            subscriptionKinds.append(.video)
        }

        for kind in subscriptionKinds {
            os_log(
                .debug,
                log: .streamSubscriptionService,
                "%{private}s, Subscribe to stream %{private}s for %{private}s",
                memberDescription,
                stream.getUri(),
                kind.description
            )

            let subscriber = Subscriber(roomExpress: roomExpress, stream: stream, kind: kind)

            addSubscriber(subscriber)

            subscriber.delegate = self
            subscriber.delegateQueue = queue
            subscriber.subscribe()
        }
    }

    func makeSubscriptionWatchdog() -> Watchdog {
        Watchdog(timeInterval: subscriptionWaitTime, queue: queue) { [weak self] in
            guard let self = self else { return }

            os_log(
                .debug,
                log: .streamSubscriptionService,
                "%{private}s, Subscription timeout is reached.",
                self.memberDescription
            )

            self.disposeSubscriptionWatchdog()
            self.subscribeNextCandidateStreamIfPossible()
        }
    }

    func disposeSubscriptionWatchdog() {
        subscriptionWatchdog?.cancel()
        subscriptionWatchdog = nil
    }

    func addFailureStream(_ stream: PhenixStream) {
        dispatchPrecondition(condition: .onQueue(queue))

        failureStreamURIs.insert(stream.getUri())
    }

    /// Remove streams from the failed stream set which previously existed, but does not exist anymore in the current stream set.
    func clearFailureStreams(currentStreams: [PhenixStream]) {
        dispatchPrecondition(condition: .onQueue(queue))

        failureStreamURIs = failureStreamURIs.filter { uri in
            currentStreams.contains { $0.getUri() == uri }
        }
    }

    // MARK: - Subscribers

    func addSubscriber(_ subscriber: Subscriber) {
        dispatchPrecondition(condition: .onQueue(queue))

        subscribers.append(subscriber)
    }

    func removeSubscriber(_ subscriber: Subscriber) {
        dispatchPrecondition(condition: .onQueue(queue))

        subscribers.removeAll { $0 == subscriber }
    }

    func disposeSubscribers() {
        dispatchPrecondition(condition: .onQueue(queue))

        subscribers.forEach { $0.dispose() }
        subscribers.removeAll()
    }

    // MARK: - Subscriptions

    func addSubscription(_ subscription: Subscription) {
        dispatchPrecondition(condition: .onQueue(queue))

        subscriptions.append(subscription)
    }

    func removeSubscriptions() {
        dispatchPrecondition(condition: .onQueue(queue))

        subscriptions.removeAll()
    }

    func disposeSubscriptions() {
        dispatchPrecondition(condition: .onQueue(queue))

        subscriptions.forEach { $0.dispose() }
        subscriptions.removeAll()
    }

    // MARK: - Candidates

    func removeCandidateStream(_ stream: PhenixStream) {
        dispatchPrecondition(condition: .onQueue(queue))

        guard let index = candidateStreams.firstIndex(where: { $0.getUri() == stream.getUri() }) else {
            return
        }

        candidateStreams.remove(at: index)
    }
}

// MARK: - Dispose
extension StreamSubscriptionService {
    func dispose() {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(
            .debug,
            log: .streamSubscriptionService,
            "%{private}s, Dispose",
            memberDescription
        )

        disposeSubscriptionWatchdog()

        observedStreamDisposable = nil
        observedStreams.removeAll()
        candidateStreams.removeAll()
        failureStreamURIs.removeAll()

        streamInProcess = nil
        disposeSubscribers()
        disposeSubscriptions()
    }
}

// MARK: - Callback methods
extension StreamSubscriptionService {
    func memberStreamDidChange(_ changes: PhenixObservableChange<NSArray>?) {
        queue.async { [weak self] in
            guard let self = self else { return }

            guard var streams = changes?.value as? [PhenixStream] else {
                return
            }

            os_log(
                .debug,
                log: .streamSubscriptionService,
                "%{private}s, Member stream list changed: %{private}s",
                self.memberDescription,
                streams.uriDescriptions()
            )

            // Remove all failure streams from the list if those
            // streams are not anymore announced.
            self.clearFailureStreams(currentStreams: streams)
            self.observedStreams = streams

            streams = self.exclude(Array(self.failureStreamURIs), from: streams)

            self.candidateStreams = streams

            guard streams.isEmpty == false else {
                os_log(
                    .debug,
                    log: .streamSubscriptionService,
                    "%{private}s, No streams",
                    self.memberDescription
                )
                return
            }

            // Start subscription process.
            // Clear out all previously pending subscription attempts - start fresh.
            self.streamInProcess = nil

            self.disposeSubscriptionWatchdog()
            self.disposeSubscribers()
            self.disposeSubscriptions()

            os_log(
                .debug,
                log: .streamSubscriptionService,
                "%{private}s, Current failure streams: %{private}s",
                self.memberDescription,
                self.failureStreamURIs.description
            )

            os_log(
                .debug,
                log: .streamSubscriptionService,
                "%{private}s, Current candidate streams: %{private}s",
                self.memberDescription,
                self.candidateStreams.uriDescriptions()
            )

            self.subscribeNextCandidateStreamIfPossible()
        }
    }
}

// MARK: - SubscriberDelegate
extension StreamSubscriptionService: SubscriberDelegate {
    func subscriber(_ subscriber: Subscriber, didSubscribeWith subscription: Subscription) {
        os_log(
            .debug,
            log: .streamSubscriptionService,
            "%{private}s, Did receive new subscription: %{private}s",
            memberDescription,
            subscription.description
        )

        removeSubscriber(subscriber)

        addSubscription(subscription)
        subscription.delegate = self
        subscription.delegateQueue = queue

        delegateQueue.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.subscriptionService(self, didSubscribeTo: subscription)
        }

        // Create a watchdog to wait for non-noData quality callbacks.
        if subscriptionWatchdog == nil {
            subscriptionWatchdog = makeSubscriptionWatchdog()
            subscriptionWatchdog?.start()
        }

        subscription.observeDataQuality()
    }

    func subscriber(
        _ subscriber: Subscriber,
        didFailToSubscribeTo stream: PhenixStream,
        with kind: StreamSubscriptionService.Subscription.Kind
    ) {
        os_log(
            .debug,
            log: .streamSubscriptionService,
            "%{private}s, Did fail to subscribe stream %{private}s for %{private}s",
            memberDescription,
            stream.getUri(),
            kind.description
        )

        // Clear all the rest subscribers, because the current
        // stream can be considered as dead.
        disposeSubscribers()
        streamInProcess = nil

        // Mark current stream as a failure stream.
        addFailureStream(stream)
        removeCandidateStream(stream)

        subscribeNextCandidateStreamIfPossible()
    }
}

// MARK: - SubscriptionDelegate
extension StreamSubscriptionService: SubscriptionDelegate {
    func subscription(_ subscription: Subscription, didReceiveQuality status: PhenixDataQualityStatus) {
        os_log(
            .debug,
            log: .streamSubscriptionService,
            "%{private}s, Did receive %{private}s subscription data quality: %{private}s",
            memberDescription,
            subscription.kind.description,
            status.description
        )

        if status != .noData {
            // Check if all subscribers have finished subscribing and
            // all subscriptions have non-noData quality status.

            guard subscribers.isEmpty else {
                return
            }

            let candidateSubscriptionsAreValid = subscriptions.allSatisfy {
                $0.lastKnownDataQuality != .noData && $0.lastKnownDataQuality != .none
            }

            guard candidateSubscriptionsAreValid else {
                return
            }

            // All subscriptions produce valid data, stream is alive.
            // Begin clean-up process and move subscriptions away from
            // this service.

            // Cancel the watchdog.
            disposeSubscriptionWatchdog()
            streamInProcess = nil

            let tempSubscriptions = subscriptions

            // Clear the delegates, so that them would not point to
            // this service class anymore.
            subscriptions.forEach { $0.delegate = nil }

            // Clear out the subscriptions list to be able to keep
            // only the new subscriptions for the next stream
            // subscription attempt.
            removeSubscriptions()

            delegateQueue.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.subscriptionService(self, didReceiveDataFrom: tempSubscriptions)
            }
        }
    }

    func subscription(_ subscription: Subscription, streamDidEndWith reason: PhenixStreamEndedReason) {
        queue.async { [weak self] in
            guard let self = self else { return }

            os_log(
                .debug,
                log: .streamSubscriptionService,
                "%{private}s, Did receive %{private}s subscription stream ended callback with reason: %{private}s",
                self.memberDescription,
                subscription.kind.description,
                reason.rawValue
            )

            subscription.dispose()
        }
    }
}

// MARK: - Helper extensions
fileprivate extension PhenixStream {
    typealias URI = String
}

fileprivate extension Array where Element: PhenixStream {
    func uriDescriptions() -> String {
        self.map { $0.getUri() }
            .description
    }
}

fileprivate extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}

extension PhenixDataQualityStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .noData:
            return "noData"
        case .audioOnly:
            return "audioOnly"
        case .all:
            return "all"
        @unknown default:
            fatalError("Unknown Data Quality service: \(self.rawValue)")
        }
    }
}
