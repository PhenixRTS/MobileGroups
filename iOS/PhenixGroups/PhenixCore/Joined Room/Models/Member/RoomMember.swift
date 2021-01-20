//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

internal protocol MemberRepresentation: AnyObject {
    var identifier: String { get }
}

public class RoomMember: MemberRepresentation {
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
    private let audioTracks: [PhenixMediaStreamTrack]?
    private var subscriber: PhenixExpressSubscriber?
    private var renderer: PhenixRenderer?
    private var streams: [PhenixStream]
    private var subscriptionState: SubscriptionState = .notSubscribed
    private var streamDisposable: PhenixDisposable?

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
    internal var audioLevelObservations = [ObjectIdentifier: AudioLevelObservation]()
    internal var videoObservations = [ObjectIdentifier: VideoObservation]()

    public let isSelf: Bool
    public let screenName: String
    public var previewLayer: VideoLayer
    public private(set) var media: RoomMemberMediaController?

    internal init(_ member: PhenixMember, isSelf: Bool, roomExpress: PhenixRoomExpress, queue: DispatchQueue = .main, renderer: PhenixRenderer? = nil, audioTracks: [PhenixMediaStreamTrack]? = nil) {
        self.queue = queue
        self.isSelf = isSelf
        self.streams = []
        self.renderer = renderer
        self.audioTracks = audioTracks
        self.phenixMember = member
        self.roomExpress = roomExpress
        self.screenName = (member.getObservableScreenName()?.getValue() ?? "N/A") as String

        self.previewLayer = VideoLayer()
    }

    internal func observeStreams() {
        queue.async { [weak self] in
            guard let self = self else { return }
            os_log(.debug, log: .roomMember, "Observe streams (%{PRIVATE}s)", self.description)
            self.streamDisposable = self.phenixMember.getObservableStreams().subscribe(self.memberStreamDidChange)
        }
    }

    internal func dispose() {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(.debug, log: .roomMember, "Dispose, (%{PRIVATE}s)", self.description)

        self.streamDisposable = nil
        self.subscriber = nil
        self.renderer = nil

        self.media?.dispose()
        self.media = nil
    }
}

// MARK: - Private methods
private extension RoomMember {
    func setupMediaController(for stream: PhenixStream) {
        dispatchPrecondition(condition: .onQueue(queue))

        let audioTracks: [PhenixMediaStreamTrack]? = subscriber?.getAudioTracks() ?? self.audioTracks
        media = RoomMemberMediaController(stream: stream, renderer: renderer, audioTracks: audioTracks, queue: queue, memberRepresentation: self)
        media?.delegate = self
        media?.observeAudioLevel()
        media?.observeAudioStream()
        media?.observeVideoStream()
    }

    func resetPreview() {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(.debug, log: .roomMember, "Reset preview (%{PRIVATE}s)", description)
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
            setupMediaController(for: stream)

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

        roomExpress.subscribe(toMemberStream: stream, options) { [weak self] status, subscriber, renderer in
            guard let self = self else { return }

            self.queue.async {
                os_log(.debug, log: .roomMember, "Member subscription callback with status - %{PRIVATE}s, (%{PRIVATE}s)", String(describing: status.rawValue), self.description)

                switch status {
                case .ok:
                    self.subscriptionState = .subscribed
                    self.subscriber = subscriber
                    self.renderer = renderer

                    self.setupMediaController(for: stream)

                    completion?(true)

                default:
                    self.subscriptionState = .notSubscribed

                    completion?(false)
                }
            }
        }
    }

    func options(for type: SubscriptionType) -> PhenixSubscribeToMemberStreamOptions {
        dispatchPrecondition(condition: .onQueue(queue))

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

            self.subscriptionState = .notSubscribed

            self.subscriber = nil
            self.media?.dispose()
            self.media = nil

            self.process(streams)
        }
    }
}

// MARK: - CustomStringConvertible
extension RoomMember: CustomStringConvertible {
    public var description: String {
        "RoomMember, session identifier: \(identifier) name: \(screenName), isSelf: \(isSelf), media: \(media?.description ?? "-")"
    }
}

// MARK: - MediaDelegate
extension RoomMember: MediaDelegate {
    func audioLevelDidChange(decibel: Double) {
        dispatchPrecondition(condition: .onQueue(queue))

        audioLevelDidChange(decibel)
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
