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

    internal let queue: DispatchQueue

    internal var identifier: String {
        guard let id = phenixMember.getSessionId() else {
            fatalError("Session ID must always be available")
        }
        return id
    }
    internal let phenixMember: PhenixMember
    internal weak var delegate: RoomMemberDelegate?
    internal weak var roomExpress: PhenixRoomExpress?
    internal var stream: PhenixStream?
    internal var subscriber: PhenixExpressSubscriber?
    internal var subscriptionType: SubscriptionType?
    internal var subscriptionState: SubscriptionState = .notSubscribed
    internal var streamDisposable: PhenixDisposable?
    internal var mediaDisposables = [PhenixDisposable]()
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

    internal init(_ member: PhenixMember, isSelf: Bool, roomExpress: PhenixRoomExpress, rootQueue: DispatchQueue) {
        self.phenixMember = member
        self.isSelf = isSelf
        self.roomExpress = roomExpress
        self.screenName = (member.getObservableScreenName()?.getValue() ?? "N/A") as String
        self.queue = DispatchQueue(label: "com.phenixrts.suite.groups.core.RoomMember", qos: .userInitiated, target: rootQueue)

        self.previewLayer = VideoLayer()
    }

    internal func observeStreams() {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            os_log(.debug, log: .roomMember, "Observe streams (%{PRIVATE}s)", self.description)
            self.streamDisposable = self.phenixMember.getObservableStreams()?.subscribe(self.memberStreamDidChange)
        }
    }

    internal func observeAudioStream() throws {
        dispatchPrecondition(condition: .onQueue(queue))
        guard let stream = stream else {
            os_log(.debug, log: .roomMember, "Cannot subscribe for audio changes, stream not provided, (%{PRIVATE}s)", self.description)
            throw StreamObservationError.streamNotProvided
        }

        os_log(.debug, log: .roomMember, "Observe audio stream changes (%{PRIVATE}s)", description)
        stream.getObservableAudioState()?.subscribe(audioStateDidChange)?.append(to: &mediaDisposables)
    }

    internal func observeVideoStream() throws {
        dispatchPrecondition(condition: .onQueue(queue))
        guard let stream = stream else {
            os_log(.debug, log: .roomMember, "Cannot subscribe for video changes, stream not provided, (%{PRIVATE}s)", self.description)
            throw StreamObservationError.streamNotProvided
        }

        os_log(.debug, log: .roomMember, "Observe video stream changes (%{PRIVATE}s)", description)
        stream.getObservableVideoState()?.subscribe(videoStateDidChange)?.append(to: &mediaDisposables)
    }

    private func resetSubscription() {
        dispatchPrecondition(condition: .onQueue(queue))
        os_log(.debug, log: .roomMember, "Reset subscription (%{PRIVATE}s)", description)

        subscriptionState = .notSubscribed
        subscriber?.stop()
        subscriber = nil
        stream = nil
    }

    private func resetStream() {
        dispatchPrecondition(condition: .onQueue(queue))
        os_log(.debug, log: .roomMember, "Reset stream (%{PRIVATE}s)", description)

        stream = nil
        streamDisposable = nil
    }

    private func resetObservers() {
        dispatchPrecondition(condition: .onQueue(queue))
        os_log(.debug, log: .roomMember, "Reset observers (%{PRIVATE}s)", self.description)

        mediaDisposables.removeAll()
    }

    private func resetPreview() {
        os_log(.debug, log: .roomMember, "Reset preview (%{PRIVATE}s)", self.description)
        DispatchQueue.main.async { [weak self] in
            self?.previewLayer.removeFromSuperlayer()
        }
    }

    internal func dispose() {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }

            os_log(.debug, log: .roomMember, "Dispose, (%{PRIVATE}s)", self.description)

            self.resetSubscription()
            self.resetObservers()
            self.resetStream()
        }
    }

    internal func subscribe(to stream: PhenixStream, with type: RoomMember.SubscriptionType, completion: @escaping (Bool) -> Void) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }

            guard self.subscriptionState == .notSubscribed else {
                // If member is already subscribed or pending, no need to re-subscribe.
                os_log(.debug, log: .roomMember, "Canceling new subscription process for member because of its subscription state, (%{PRIVATE}s)", self.description)

                completion(false)

                return
            }

            self.subscriptionState = .pending
            self.stream = stream

            if self.isSelf {
                /*
                 There is no need to subscribe for media for Self object, because we can use media straight from the
                 device via the UserMediaStreamController.
                 We only need to observe for the media state changes (audio and video) for Self member,
                 to receive the updates if media gets enabled/disabled.
                 */
                os_log(.debug, log: .roomMember, "Member is Self, only subscribe for media state changes, (%{PRIVATE}s)", self.description)

                self.subscriptionState = .subscribed
                try? self.observeAudioStream()
                try? self.observeVideoStream()

                completion(true)

                return
            }

            // Save subscription type.
            // For "self" member we do not need to save this, because it is using local media
            self.subscriptionType = type

            let options: PhenixSubscribeToMemberStreamOptions = {
                switch type {
                case .audio:
                    return PhenixOptionBuilder.createSubscribeToMemberAudioStreamOptions()

                case .video:
                    return PhenixOptionBuilder.createSubscribeToMemberVideoStreamOptions(with: self.previewLayer)
                }
            }()

            os_log(.debug, log: .roomMember, "Subscribe to member stream with %{PRIVATE}s type, (%{PRIVATE}s)", String(describing: type), self.description)

            guard let roomExpress = self.roomExpress else {
                fatalError("Room Express must be provided")
            }

            roomExpress.subscribe(toMemberStream: stream, options) { status, subscriber, _ in
                self.queue.async {
                    os_log(.debug, log: .roomMember, "Member subscription callback with status - %{PRIVATE}s, (%{PRIVATE}s)", String(describing: status.rawValue), self.description)

                    switch status {
                    case .ok:
                        self.subscriptionState = .subscribed
                        self.subscriber = subscriber

                        try? self.observeAudioStream()
                        try? self.observeVideoStream()

                        completion(true)

                    default:
                        self.subscriptionState = .notSubscribed
                        self.stream = nil

                        completion(false)
                    }
                }
            }
        }
    }
}

// MARK: - Observable callback methods
internal extension RoomMember {
    func memberStreamDidChange(_ changes: PhenixObservableChange<NSArray>?) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }

            guard let streams = changes?.value as? [PhenixStream] else {
                return
            }

            os_log(.debug, log: .roomMember, "Member stream did change callback received, (%{PRIVATE}s)", self.description)

            self.resetSubscription()
            self.resetObservers()

            self.delegate?.memberStreamDidChange(self, streams: streams)
        }
    }

    func audioStateDidChange(_ changes: PhenixObservableChange<NSNumber>?) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }

            guard let value = changes?.value else { return }
            guard let state = PhenixTrackState(rawValue: Int(truncating: value)) else { return }

            self.isAudioAvailable = state == .enabled
        }
    }

    func videoStateDidChange(_ changes: PhenixObservableChange<NSNumber>?) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }
            guard let value = changes?.value else { return }
            guard let state = PhenixTrackState(rawValue: Int(truncating: value)) else { return }

            self.isVideoAvailable = state == .enabled
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
