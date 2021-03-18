//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

internal protocol RoomMemberRepresentation: AnyObject {
    var identifier: String { get }
}

public class RoomMember: RoomMemberRepresentation {
    public enum SubscriptionType {
        case audio
        case video
    }

    private let roomExpress: PhenixRoomExpress
    private let phenixMember: PhenixMember

    private let localMemberRenderer: PhenixRenderer?
    private let localMemberAudioTracks: [PhenixMediaStreamTrack]?

    internal let queue: DispatchQueue
    internal let mediaController: RoomMemberMediaController
    internal let subscriptionController: RoomMemberStreamSubscriptionController

    internal var identifier: String { phenixMember.getSessionId() }
    internal var audioObservations = [ObjectIdentifier: AudioObservation]()
    internal var videoObservations = [ObjectIdentifier: VideoObservation]()
    internal var audioLevelObservations = [ObjectIdentifier: AudioLevelObservation]()

    public let isSelf: Bool
    public var screenName: String { phenixMember.getObservableScreenName().getValueOrDefault() as String }
    public var previewLayer: VideoLayer
    public var media: (MediaAvailability & RecentAudioLevelProvider) { mediaController }

    private init(
        roomExpress: PhenixRoomExpress,
        member: PhenixMember,
        queue: DispatchQueue = .main,
        isSelf: Bool,
        localMemberRenderer: PhenixRenderer? = nil,
        localMemberAudioTracks: [PhenixMediaStreamTrack]? = nil
    ) {
        self.queue = queue
        self.isSelf = isSelf
        self.roomExpress = roomExpress
        self.phenixMember = member
        self.localMemberRenderer = localMemberRenderer
        self.localMemberAudioTracks = localMemberAudioTracks

        self.previewLayer = VideoLayer()
        self.mediaController = RoomMemberMediaController(queue: queue)
        self.subscriptionController = RoomMemberStreamSubscriptionController(
            roomExpress: roomExpress,
            queue: queue
        )

        self.mediaController.delegate = self
        self.mediaController.memberRepresentation = self

        self.subscriptionController.delegate = self
        self.subscriptionController.memberRepresentation = self
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

    func observeStreams() {
        queue.async { [weak self] in
            guard let self = self else { return }
            os_log(.debug, log: .roomMember, "Observe stream changes, (%{PRIVATE}s)", self.description)
            self.subscriptionController.observeMemberStreams(self.phenixMember)
        }
    }

    func dispose() {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(.debug, log: .roomMember, "Dispose, (%{PRIVATE}s)", description)

        subscriptionController.dispose()
        mediaController.dispose()
    }
}

// MARK: - Private methods
private extension RoomMember {
    func resetPreview() {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(.debug, log: .roomMember, "Reset preview (%{PRIVATE}s)", description)

        DispatchQueue.main.async { [weak self] in
            self?.previewLayer.removeFromSuperlayer()
        }
    }
}

// MARK: - CustomStringConvertible
extension RoomMember: CustomStringConvertible {
    public var description: String {
        "RoomMember(session identifier: \(identifier), isSelf: \(isSelf), subscription: \(subscriptionController), name: \(screenName), media: \(mediaController))"
    }
}

// MARK: - RoomMemberMediaDelegate
extension RoomMember: RoomMemberMediaDelegate {
    func audioLevelDidChange(decibel: Double) {
        dispatchPrecondition(condition: .onQueue(queue))

        audioLevelDidChange(decibel)
    }
}

extension RoomMember: RoomMemberStreamSubscriptionDelegate {
    func streamSubscriptionController(_ controller: RoomMemberStreamSubscriptionController, canSubscribeTo streams: [PhenixStream]) -> Bool {
        dispatchPrecondition(condition: .onQueue(queue))

        if isSelf {
            // There is no need to subscribe to stream for local member,
            // because we can use media straight from the device via
            // the UserMediaStreamController. We only need to observe
            // for the media state changes (audio and video) for local
            // member, to receive the updates if media gets
            // enabled/disabled.

            os_log(
                .debug,
                log: .roomMember,
                "Do not subscribe to stream. Only observe the state changes. This is „Self“ member, (%{PRIVATE}s)",
                description
            )

            if let stream = streams.first {
                subscriptionController.desiredSubscriptionTypes = [.audio, .video]

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
            }
            return false
        } else {
            return true
        }
    }

    func streamSubscriptionController(_ controller: RoomMemberStreamSubscriptionController, didSubscribeWith subscription: RoomMemberStreamSubscription) {
        dispatchPrecondition(condition: .onQueue(queue))

        // After successful subscription, start rendering
        // and create necessary state change providers
        // for the subscribed stream.

        switch subscription.subscriptionType {
        case .video:
            subscription.renderer.start(previewLayer)

            let videoStateProvider = MemberStreamVideoStateProvider(stream: subscription.stream, queue: queue)
            videoStateProvider.memberRepresentation = self
            mediaController.setVideoStateProvider(videoStateProvider)

        case .audio:
            subscription.renderer.start()

            let audioStateProvider = MemberStreamAudioStateProvider(stream: subscription.stream, queue: queue)
            audioStateProvider.memberRepresentation = self
            mediaController.setAudioStateProvider(audioStateProvider)

            let audioLevelProvider = MemberStreamAudioLevelProvider(
                renderer: subscription.renderer,
                audioTracks: subscription.subscriber.getAudioTracks(),
                queue: queue
            )
            audioLevelProvider.memberRepresentation = self
            mediaController.setAudioLevelProvider(audioLevelProvider)
        }
    }

    func streamSubscriptionControllerDidDisposeSubscriptions(_ controller: RoomMemberStreamSubscriptionController) {
        dispatchPrecondition(condition: .onQueue(queue))

        // When stream changes, it must dispose all previously
        // created state change providers and wait for new
        // stream subscriptions and then recreate providers.

        mediaController.dispose()
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
        guard let lhsLastUpdate = lhs.phenixMember.getObservableLastUpdate().getValueOrDefault() as Date? else {
            return true
        }

        guard let rhsLastUpdate = rhs.phenixMember.getObservableLastUpdate().getValueOrDefault() as Date? else {
            return false
        }

        return lhsLastUpdate < rhsLastUpdate
    }
}
