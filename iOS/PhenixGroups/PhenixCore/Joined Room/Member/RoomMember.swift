//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

// swiftlint:disable file_length

import Foundation
import os.log
import PhenixSdk

internal protocol RoomMemberRepresentation: AnyObject {
    var identifier: String { get }
}

public class RoomMember: RoomMemberRepresentation {
    public enum State {
        case active, away, pending, removed
    }

    private let roomExpress: PhenixRoomExpress
    private let phenixMember: PhenixMember

    private let localMemberRenderer: PhenixRenderer?
    private let localMemberAudioTracks: [PhenixMediaStreamTrack]?
    private let streamSubscriptionService: StreamSubscriptionService
    private var statusWatchdog: Watchdog?

    internal let queue: DispatchQueue
    internal let mediaController: RoomMemberMediaController

    internal var identifier: String { phenixMember.getSessionId() }
    internal var audioObservations = [ObjectIdentifier: AudioObservation]()
    internal var videoObservations = [ObjectIdentifier: VideoObservation]()
    internal var audioLevelObservations = [ObjectIdentifier: AudioLevelObservation]()
    internal var stateObservations = [ObjectIdentifier: StateObservation]()
    internal var subscriptions: [StreamSubscriptionService.Subscription] = []

    internal weak var membersControllerDelegate: RoomMemberControllerDelegate?

    public let isSelf: Bool
    public private(set) var state: State {
        didSet {
            os_log(
                .debug,
                log: .roomMember,
                "%{private}s, State did change to %{private}s",
                identifier,
                String(describing: state)
            )

            stateDidChange(state)
        }
    }

    public var screenName: String { phenixMember.getObservableScreenName().getValueOrDefault() as String }
    public var previewLayer: VideoLayer
    public var media: (MediaAvailability & RecentAudioLevelProvider) { mediaController }
    public var isSubscribed: Bool { subscriptions.isEmpty == false }

    public var subscribesToVideo: Bool {
        subscriptions.contains { $0.kind == .video }
            || streamSubscriptionService.subscriptions.contains { $0.kind == .video }
            || streamSubscriptionService.subscribers.contains { $0.kind == .video }
    }

    private init(
        roomExpress: PhenixRoomExpress,
        member: PhenixMember,
        queue: DispatchQueue = .main,
        isSelf: Bool,
        localMemberRenderer: PhenixRenderer? = nil,
        localMemberAudioTracks: [PhenixMediaStreamTrack]? = nil
    ) {
        self.state = isSelf ? .active : .pending
        self.queue = queue
        self.isSelf = isSelf
        self.roomExpress = roomExpress
        self.phenixMember = member
        self.localMemberRenderer = localMemberRenderer
        self.localMemberAudioTracks = localMemberAudioTracks

        self.previewLayer = VideoLayer()
        self.mediaController = RoomMemberMediaController(queue: queue)
        self.streamSubscriptionService = StreamSubscriptionService(roomExpress: roomExpress)
        self.streamSubscriptionService.queue = queue
        self.streamSubscriptionService.delegateQueue = queue

        self.mediaController.delegate = self
        self.mediaController.memberRepresentation = self

        self.streamSubscriptionService.delegate = self
        self.streamSubscriptionService.memberRepresentation = self
    }

    convenience init(remoteMember: PhenixMember, roomExpress: PhenixRoomExpress, queue: DispatchQueue) {
        self.init(roomExpress: roomExpress, member: remoteMember, queue: queue, isSelf: false)
    }

    convenience init(
        localMember: PhenixMember,
        roomExpress: PhenixRoomExpress,
        renderer: PhenixRenderer?,
        audioTracks: [PhenixMediaStreamTrack]?,
        queue: DispatchQueue
    ) {
        self.init(
            roomExpress: roomExpress,
            member: localMember,
            queue: queue,
            isSelf: true,
            localMemberRenderer: renderer,
            localMemberAudioTracks: audioTracks
        )
    }
}

// MARK: - Internal methods
internal extension RoomMember {
    func observeStreams() {
        queue.async { [weak self] in
            guard let self = self else { return }
            os_log(.debug, log: .roomMember, "%{private}s, Observe stream changes", self.description)
            self.streamSubscriptionService.observeMemberStreams(self.phenixMember)
        }
    }

    func dispose() {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(.debug, log: .roomMember, "%{private}s, Dispose", description)

        disposeStreamSubscriptions()
        streamSubscriptionService.dispose()
        mediaController.dispose()
    }
}

// MARK: - Private methods
private extension RoomMember {
    func resetPreview() {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(.debug, log: .roomMember, "%{private}s, Reset preview", description)

        DispatchQueue.main.async { [weak self] in
            self?.previewLayer.removeFromSuperlayer()
        }
    }

    func disposeStreamSubscriptions() {
        dispatchPrecondition(condition: .onQueue(queue))

        subscriptions.forEach { $0.dispose() }
        subscriptions.removeAll()

        mediaController.setAudioLevelProvider(nil)
        mediaController.setAudioStateProvider(nil)
        mediaController.setVideoStateProvider(nil)
    }

    func makeStatusWatchdog() -> Watchdog {
        Watchdog(timeInterval: 10, queue: queue) { [weak self] in
            self?.setState(.pending)
        }
    }

    func disposeStatusWatchdog() {
        statusWatchdog?.cancel()
        statusWatchdog = nil
    }

    func setState(_ state: State) {
        dispatchPrecondition(condition: .onQueue(queue))

        guard self.state != state else {
            return
        }

        self.state = state

        switch state {
        case .active:
            disposeStatusWatchdog()

        case .away:
            if statusWatchdog == nil {
                // Start a watchdog, which will change the
                // state to pending after specific time period.
                // This happens if the member does not provide
                // data for the specific time period and can
                // be considered as an offline member.
                statusWatchdog = makeStatusWatchdog()
                statusWatchdog?.start()
            }

        case .pending:
            disposeStatusWatchdog()
            streamSubscriptionService.subscribeNextCandidateStreamIfPossible()

        case .removed:
            disposeStreamSubscriptions()
        }
    }
}

// MARK: - CustomStringConvertible
extension RoomMember: CustomStringConvertible {
    public var description: String {
        "RoomMember(id: \(identifier), isSelf: \(isSelf), state: \(state), name: \(screenName))"
    }
}

// MARK: - RoomMemberMediaDelegate
extension RoomMember: RoomMemberMediaDelegate {
    func audioLevelDidChange(decibel: Double) {
        dispatchPrecondition(condition: .onQueue(queue))

        audioLevelDidChange(decibel)
    }
}

// MARK: - Hashable
extension RoomMember: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

// MARK: - Equatable
extension RoomMember: Equatable {
    public static func == (lhs: RoomMember, rhs: RoomMember) -> Bool {
        lhs.identifier == rhs.identifier
    }

    public static func == (lhs: RoomMember, rhs: PhenixMember) -> Bool {
        lhs.identifier == rhs.getSessionId()
    }

    public static func == (lhs: PhenixMember, rhs: RoomMember) -> Bool {
        lhs.getSessionId() == rhs.identifier
    }

    public static func != (lhs: RoomMember, rhs: PhenixMember) -> Bool {
        lhs.identifier != rhs.getSessionId()
    }

    public static func != (lhs: PhenixMember, rhs: RoomMember) -> Bool {
        lhs.getSessionId() != rhs.identifier
    }
}

// MARK: - Comparable
extension RoomMember: Comparable {
    public static func < (lhs: RoomMember, rhs: RoomMember) -> Bool {
        guard let lhsLastUpdate = lhs.phenixMember.getObservableLastUpdate().getValueOrDefault() as Date? else {
            return true
        }

        guard let rhsLastUpdate = rhs.phenixMember.getObservableLastUpdate().getValueOrDefault() as Date? else {
            return false
        }

        return lhsLastUpdate < rhsLastUpdate
    }
}

// MARK: - StreamSubscriptionServiceDelegate
extension RoomMember: StreamSubscriptionServiceDelegate {
    func subscriptionServiceCanSubscribeForVideo(_ service: StreamSubscriptionService) -> Bool {
        dispatchPrecondition(condition: .onQueue(queue))

        return membersControllerDelegate?.canSubscribeForVideo() ?? false
    }

    func subscriptionService(
        _ service: StreamSubscriptionService,
        shouldSubscribeTo stream: PhenixStream
    ) -> StreamSubscriptionProcessAction {
        dispatchPrecondition(condition: .onQueue(queue))

        if isSelf {
            // There is no need to subscribe to stream for local member,
            // because we can use media straight from the device via
            // the UserMediaStreamController. We only need to observe
            // for the media state changes (audio and video) for local
            // member, to receive the updates if media gets
            // enabled/disabled.

            let videoStateProvider = MemberStreamVideoStateProvider(stream: stream, queue: queue)
            videoStateProvider.memberRepresentation = self
            mediaController.setVideoStateProvider(videoStateProvider)

            let audioStateProvider = MemberStreamAudioStateProvider(stream: stream, queue: queue)
            audioStateProvider.memberRepresentation = self
            mediaController.setAudioStateProvider(audioStateProvider)

            guard let renderer = localMemberRenderer else {
                fatalError("Fatal error. PhenixRenderer for the local member is required.")
            }

            guard let audioTracks = localMemberAudioTracks else {
                fatalError("Fatal error. PhenixMediaStreamTrack array (audio tracks) for the local member is required.")
            }

            let audioLevelProvider = MemberStreamAudioLevelProvider(
                renderer: renderer,
                audioTracks: audioTracks,
                queue: queue
            )
            audioLevelProvider.memberRepresentation = self
            mediaController.setAudioLevelProvider(audioLevelProvider)

            state = .active

            return .exit
        } else if subscriptions.contains(where: { $0.stream.getUri() == stream.getUri() }) {
            // Stream, to which we are currently trying to subscribe,
            // already contains an active subscription(s). We can
            // skip this stream, no need to subscribe to it once more.
            return .cancel
        } else {
            // All good, service can proceed with the stream subscription.
            return .continue
        }
    }

    func subscriptionService(
        _ service: StreamSubscriptionService,
        didSubscribeTo subscription: StreamSubscriptionService.Subscription
    ) {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(
            .debug,
            log: .roomMember,
            "%{private}s, Start renderer for subscription: %{private}s",
            description,
            subscription.description
        )

        // After successful subscription, start rendering
        // and create necessary state change providers
        // for the subscribed stream.

        switch subscription.kind {
        case .video:
            subscription.renderer.start(previewLayer)

        case .audio:
            subscription.renderer.start()
        }
    }

    func subscriptionService(
        _ service: StreamSubscriptionService,
        didReceiveDataFrom subscriptions: [StreamSubscriptionService.Subscription]
    ) {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(
            .debug,
            log: .roomMember,
            "%{private}s, Received active subscriptions: %{private}s",
            description,
            subscriptions.description
        )

        disposeStreamSubscriptions()

        for subscription in subscriptions {
            subscription.delegate = self

            switch subscription.kind {
            case .video:
                let videoStateProvider = MemberStreamVideoStateProvider(stream: subscription.stream, queue: queue)
                videoStateProvider.memberRepresentation = self
                mediaController.setVideoStateProvider(videoStateProvider)

            case .audio:
                let audioStateProvider = MemberStreamAudioStateProvider(stream: subscription.stream, queue: queue)
                audioStateProvider.memberRepresentation = self
                mediaController.setAudioStateProvider(audioStateProvider)

                let audioLevelProvider = MemberStreamAudioLevelProvider(
                    renderer: subscription.renderer,
                    audioTracks: subscription.subscriber.getAudioTracks(),
                    queue: self.queue
                )
                audioLevelProvider.memberRepresentation = self
                mediaController.setAudioLevelProvider(audioLevelProvider)
            }
        }

        self.subscriptions = subscriptions
        setState(.active)
    }
}

// MARK: - SubscriptionDelegate
extension RoomMember: SubscriptionDelegate {
    func subscription(
        _ subscription: StreamSubscriptionService.Subscription,
        didReceiveQuality status: PhenixDataQualityStatus
    ) {
        queue.async { [weak self] in
            guard let self = self else { return }

            os_log(
                .debug,
                log: .roomMember,
                "%{private}s, Did receive %{private}s subscription data quality: %{private}s",
                self.description,
                subscription.kind.description,
                status.description
            )

            if status == .noData {
                // If a member background the application, member's video stream will
                // stop publishing and therefore all other members will receive
                // "noData" quality callback. This member still can transmit audio
                // and is still online.
                // Unfortunately, we cannot trust the audio data quality, because
                // the SDK generates additional audio, when the member does not
                // generate.
                // A workaround here is that we check if the appropriate stream state
                // is ON and only then move the member to the "away" state.
                let isEnabled: Bool = {
                    switch subscription.kind {
                    case .audio:
                        return self.media.isAudioAvailable
                    case .video:
                        return self.media.isVideoAvailable
                    }
                }()

                if isEnabled {
                    self.setState(.away)
                } else {
                    os_log(
                        .debug,
                        log: .roomMember,
                        "%{private}s, Stream publisher is disabled, ignore data quality callback.",
                        self.description
                    )
                }
            } else {
                self.setState(.active)
            }
        }
    }

    func subscription(
        _ subscription: StreamSubscriptionService.Subscription,
        streamDidEndWith reason: PhenixStreamEndedReason
    ) {
        queue.async { [weak self] in
            guard let self = self else { return }

            os_log(
                .debug,
                log: .roomMember,
                "%{private}s, Did receive %{private}s subscription stream ended callback with reason: %{private}d",
                self.description,
                subscription.kind.description,
                reason.rawValue
            )

            self.disposeStreamSubscriptions()
            self.setState(.pending)
        }
    }
}
