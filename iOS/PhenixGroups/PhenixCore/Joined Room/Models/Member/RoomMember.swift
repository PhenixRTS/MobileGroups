//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

public class RoomMember {
    public enum StreamObservationError: Error {
        case streamNotProvided
    }

    public enum SubscriptionType {
        case audio
        case video
    }

    public enum SubscriptionState {
        case notSubscribed
        case pending
        case subscribed
    }

    private weak var roomExpress: PhenixRoomExpress?
    private let phenixMember: PhenixMember
    private var subscriber: PhenixExpressSubscriber?
    private var streams: [PhenixStream]
    private var subscriptionStream: PhenixStream?
    private var subscriptionState: SubscriptionState = .notSubscribed
    private var streamDisposable: PhenixDisposable?
    private var mediaDisposables = [PhenixDisposable]()

    internal let queue: DispatchQueue
    internal var identifier: String {
        guard let id = phenixMember.getSessionId() else {
            fatalError("Session ID must always be available")
        }
        return id
    }

    internal weak var roomController: RoomMemberControllerDelegate?
    internal var subscriptionType: SubscriptionType?
    internal var audioObservations = [ObjectIdentifier: AudioObservation]()
    internal var videoObservations = [ObjectIdentifier: VideoObservation]()

    public let isSelf: Bool
    public let screenName: String
    public var previewLayer: VideoLayer
    public private(set) var isAudioAvailable = false {
        didSet {
            audioStateDidChange(enabled: isAudioAvailable)
        }
    }
    public private(set) var isVideoAvailable = false {
        didSet {
            videoStateDidChange(enabled: isVideoAvailable)
        }
    }

    internal init(_ member: PhenixMember, isSelf: Bool, roomExpress: PhenixRoomExpress, queue: DispatchQueue = .main) {
        self.phenixMember = member
        self.isSelf = isSelf
        self.roomExpress = roomExpress
        self.screenName = (member.getObservableScreenName()?.getValue() ?? "N/A") as String
        self.streams = []
        self.queue = queue

        self.previewLayer = VideoLayer()
    }

    internal func observeStreams() {
        os_log(.debug, log: .roomMember, "Observe streams (%{PRIVATE}s)", description)
        streamDisposable = phenixMember.getObservableStreams()?.subscribe(memberStreamDidChange)
    }

    internal func dispose() {
        os_log(.debug, log: .roomMember, "Dispose, (%{PRIVATE}s)", description)

        resetSubscription()
        resetObservers()
        resetStream()
    }
}

// MARK: - Private methods
private extension RoomMember {
    func observeAudioStream() throws {
        guard let stream = subscriptionStream else {
            os_log(.debug, log: .roomMember, "Cannot subscribe for audio changes, stream not provided, (%{PRIVATE}s)", self.description)
            throw StreamObservationError.streamNotProvided
        }

        os_log(.debug, log: .roomMember, "Observe audio stream changes (%{PRIVATE}s)", description)
        stream.getObservableAudioState()?.subscribe(audioStateDidChange)?.append(to: &mediaDisposables)
    }

    func observeVideoStream() throws {
        guard let stream = subscriptionStream else {
            os_log(.debug, log: .roomMember, "Cannot subscribe for video changes, stream not provided, (%{PRIVATE}s)", self.description)
            throw StreamObservationError.streamNotProvided
        }

        os_log(.debug, log: .roomMember, "Observe video stream changes (%{PRIVATE}s)", description)
        stream.getObservableVideoState()?.subscribe(videoStateDidChange)?.append(to: &mediaDisposables)
    }

    func resetSubscription() {
        os_log(.debug, log: .roomMember, "Reset subscription (%{PRIVATE}s)", description)

        subscriptionState = .notSubscribed
        subscriber?.stop()
        subscriber = nil
        subscriptionStream = nil
    }

    func resetStream() {
        os_log(.debug, log: .roomMember, "Reset stream (%{PRIVATE}s)", description)

        subscriptionStream = nil
        streamDisposable = nil
    }

    func resetObservers() {
        os_log(.debug, log: .roomMember, "Reset observers (%{PRIVATE}s)", self.description)

        mediaDisposables.removeAll()
    }

    func resetPreview() {
        os_log(.debug, log: .roomMember, "Reset preview (%{PRIVATE}s)", self.description)
        DispatchQueue.main.async { [weak self] in
            self?.previewLayer.removeFromSuperlayer()
        }
    }

    func process(_ streams: [PhenixStream]) {
        dispatchPrecondition(condition: .onQueue(queue))

        self.streams = streams

        guard let controller = roomController else { return }
        guard let stream = nextStream() else { return }

        let type: SubscriptionType = controller.canSubscribeWithVideo() == true ? .video : .audio

        var handler: ((Bool) -> Void)?

        // If the current stream will fail to subscribe, we need recursively try next stream in the queue,
        // till we connect or the streams end.
        handler = { [weak self] succeeded in
            if succeeded == false, let stream = self?.nextStream() {
                self?.subscribe(to: stream, with: type, completion: handler)
            }
        }

        // Try to subscribe
        subscribe(to: stream, with: type, completion: handler)
    }

    func nextStream() -> PhenixStream? {
        dispatchPrecondition(condition: .onQueue(queue))
        if streams.isEmpty {
            return nil
        }

        return streams.removeFirst()
    }

    func subscribe(to stream: PhenixStream, with type: RoomMember.SubscriptionType, completion: ((Bool) -> Void)?) {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(.debug, log: .roomMember, "Subscribe to stream: %{PRIVATE}s, type: %{PRIVATE}s, (%{PRIVATE}s)", stream.description, String(describing: type), description)

        guard subscriptionState == .notSubscribed else {
            assertionFailure("Do not try to subscribe for a stream if there is already an active subscription")

            // If member is already subscribed or pending, no need to re-subscribe.
            os_log(.debug, log: .roomMember, "Canceling subscription process because of current subscription state, (%{PRIVATE}s)", description)

            completion?(false)
            return
        }

        subscriptionState = .pending

        if isSelf {
            /*
             There is no need to subscribe for media for Self object, because we can use media straight from the
             device via the UserMediaStreamController.
             We only need to observe for the media state changes (audio and video) for Self member,
             to receive the updates if media gets enabled/disabled.
             */
            os_log(.debug, log: .roomMember, "Member is Self, only subscribe for media state changes, (%{PRIVATE}s)", description)

            subscriptionState = .subscribed
            self.subscriptionStream = stream

            try? observeAudioStream()
            try? observeVideoStream()

            completion?(true)
            return
        }

        guard let roomExpress = self.roomExpress else {
            fatalError("Room Express must be provided")
        }

        // Save subscription type.
        // For "self" member we do not need to save this, because it is using local media
        subscriptionType = type

        let options = self.options(for: type)

        os_log(.debug, log: .roomMember, "Subscribe to member stream with %{PRIVATE}s type, (%{PRIVATE}s)", String(describing: type), description)

        roomExpress.subscribe(toMemberStream: stream, options) { [weak self] status, subscriber, _ in
            guard let self = self else { return }

            os_log(.debug, log: .roomMember, "Member subscription callback with status - %{PRIVATE}s, (%{PRIVATE}s)", String(describing: status.rawValue), self.description)

            switch status {
            case .ok:
                self.subscriptionState = .subscribed
                self.subscriber = subscriber
                self.subscriptionStream = stream

                try? self.observeAudioStream()
                try? self.observeVideoStream()

                completion?(true)

            default:
                self.subscriptionState = .notSubscribed
                self.subscriptionStream = nil

                completion?(false)
            }
        }
    }

    func options(for type: SubscriptionType) -> PhenixSubscribeToMemberStreamOptions {
        switch type {
        case .audio:
            return PhenixOptionBuilder.createSubscribeToMemberAudioStreamOptions()

        case .video:
            return PhenixOptionBuilder.createSubscribeToMemberVideoStreamOptions(with: self.previewLayer)
        }
    }
}

// MARK: - Observable callback methods
internal extension RoomMember {
    func memberStreamDidChange(_ changes: PhenixObservableChange<NSArray>?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard let streams = changes?.value as? [PhenixStream] else { return }

            os_log(.debug, log: .roomMember, "Member stream did change callback received, (%{PRIVATE}s)", self.description)

            self.resetSubscription()
            self.resetObservers()
            self.resetStream()

            self.process(streams)
        }
    }

    func audioStateDidChange(_ changes: PhenixObservableChange<NSNumber>?) {
        queue.async { [weak self] in
            guard let value = changes?.value else { return }
            guard let state = PhenixTrackState(rawValue: Int(truncating: value)) else { return }

            self?.isAudioAvailable = state == .enabled
        }
    }

    func videoStateDidChange(_ changes: PhenixObservableChange<NSNumber>?) {
        queue.async { [weak self] in
            guard let value = changes?.value else { return }
            guard let state = PhenixTrackState(rawValue: Int(truncating: value)) else { return }

            self?.isVideoAvailable = state == .enabled
        }
    }
}

// MARK: - CustomStringConvertible
extension RoomMember: CustomStringConvertible {
    public var description: String {
        "RoomMember, session identifier: \(identifier) name: \(screenName), isSelf: \(isSelf), audio: \(isAudioAvailable), video: \(isVideoAvailable)"
    }
}

// MARK: - Hashable
extension RoomMember: Hashable {
    public static func == (lhs: RoomMember, rhs: RoomMember) -> Bool {
        lhs.identifier == rhs.identifier
    }

    public static func == (lhs: RoomMember, rhs: PhenixMember) -> Bool {
        lhs.identifier == rhs.getSessionId()
    }

    public static func == (lhs: PhenixMember, rhs: RoomMember) -> Bool {
        lhs.getSessionId() == rhs.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

// MARK: - Comparable
extension RoomMember: Comparable {
    public static func < (lhs: RoomMember, rhs: RoomMember) -> Bool {
        guard let lhsLastUpdate = lhs.phenixMember.getObservableLastUpdate()?.getValue() as Date? else {
            return true
        }

        guard let rhsLastUpdate = rhs.phenixMember.getObservableLastUpdate()?.getValue() as Date? else {
            return false
        }

        return lhsLastUpdate < rhsLastUpdate
    }
}
