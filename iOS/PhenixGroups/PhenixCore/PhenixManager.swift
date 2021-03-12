//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixChat
import PhenixSdk

public final class PhenixManager: PhenixMediaChanges, PhenixOnlineStatusChanges {
    public typealias UnrecoverableErrorHandler = (_ description: String?) -> Void
    public typealias MediaCreationTimeoutHandler = () -> Void

    private var joinedRoom: JoinedRoom?
    private var chatService: PhenixChatService?
    private var onlineStatusDisposable: PhenixDisposable?
    private var enableMediaCreationOnOnlineStatusChange: Bool = false
    private var mediaCreationTimeoutHandler: MediaCreationTimeoutHandler?

    internal let queue: DispatchQueue
    internal private(set) var roomExpress: PhenixRoomExpress!
    internal var onlineStatusObservations: [ObjectIdentifier: OnlineStatusObserver]
    internal var userStreamMediaObservations: [ObjectIdentifier: UserStreamMediaObserver]

    /// Backend URL used by Phenix SDK to communicate
    public let backend: URL
    public let pcast: URL?
    /// Maximum allowed member count with video subscription at the same time.
    public let maxVideoSubscriptions: Int
    public private(set) var userMediaStreamController: UserMediaStreamController?

    /// Initializer for Phenix manager
    /// - Parameter backend: Backend URL for Phenix SDK
    public init(backend: URL, pcast: URL?, maxVideoSubscriptions: Int = 4) {
        self.pcast = pcast
        self.queue = DispatchQueue(label: "com.phenixrts.suite.groups.core", qos: .userInitiated)
        self.backend = backend
        self.maxVideoSubscriptions = maxVideoSubscriptions
        self.onlineStatusObservations = [:]
        self.userStreamMediaObservations = [:]
    }

    /// Initializes necessary instances of the PhenixSdk which provides connection and media streaming possibilities.
    ///
    /// Needs to be executed before trying to create, join or publish to a room.
    /// - Parameters:
    ///   - unrecoverableErrorCompletion: PhenixSdk unrecoverable error callback
    ///   - mediaCreationTimeoutHandler: If media stream creation reaches timeout and cannot initialize itself, executed callback.
    public func start(
        unrecoverableErrorCompletion: @escaping UnrecoverableErrorHandler,
        mediaCreationTimeoutHandler: MediaCreationTimeoutHandler?
    ) {
        os_log(.debug, log: .phenixManager, "Setup Room Express")
        self.mediaCreationTimeoutHandler = mediaCreationTimeoutHandler

        queue.sync {
            self.setupRoomExpress(backend: backend, unrecoverableErrorCompletion)
            self.processMedia()
        }
    }
}

// MARK: - Helper methods
internal extension PhenixManager {
    func set(room: JoinedRoom?) {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(.debug, log: .phenixManager, "Set new joined room: %{PRIVATE}s", room?.description ?? "nil")
        joinedRoom = room
    }

    func makeJoinedRoom(
        roomExpress: PhenixRoomExpress,
        roomService: PhenixRoomService,
        backend: URL,
        publisher: PhenixExpressPublisher? = nil,
        userMedia: UserMediaProvider? = nil
    ) -> JoinedRoom {
        dispatchPrecondition(condition: .onQueue(queue))

        let queue = self.queue

        // Re-use the same chat service or create a new one if the room was left previously.
        let chatService: PhenixChatService = self.chatService ?? PhenixChatService(roomService: roomService)

        // Save chat service if it doesn't exist already.
        if self.chatService == nil {
            os_log(.debug, log: .phenixManager, "Chat service does not exist, created a new one")
            self.chatService = chatService
        }

        // Create a media controller, which is responsible for the interactions with local device media for publishing,
        // for example, setting audio and video ON/OFF.
        let mediaController: RoomMediaController? = {
            if let publisher = publisher {
                return RoomMediaController(publisher: publisher, queue: queue)
            } else {
                return nil
            }
        }()

        // Create a member controller, which is responsible for listening for joined room member list changes,
        // new member stream observing and other things.
        let memberController = RoomMemberController(
            roomService: roomService,
            roomExpress: roomExpress,
            userMedia: userMedia,
            maxVideoSubscriptions: maxVideoSubscriptions,
            queue: queue
        )

        // Create a joined room, which is the connected room instance and also it holds the media and member controllers.
        let room = JoinedRoom(
            roomService: roomService,
            chatService: chatService,
            mediaController: mediaController,
            memberController: memberController,
            backend: backend,
            queue: queue
        )

        room.delegate = self
        mediaController?.roomRepresentation = room
        memberController.roomRepresentation = room

        return room
    }

    func disposeCurrentlyJoinedRoom() {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(.debug, log: .phenixManager, "Destroy currently joined room instance, if exist")
        joinedRoom?.dispose()
        joinedRoom = nil
    }
}

// MARK: - Setup methods
private extension PhenixManager {
    func setupRoomExpress(backend: URL, _ unrecoverableErrorCompletion: @escaping UnrecoverableErrorHandler) {
        let pcastExpressOptions = PhenixOptionBuilder.createPCastExpressOptions(
            backend: backend,
            pcast: pcast,
            unrecoverableErrorCallback: unrecoverableErrorCompletion
        )
        let roomExpressOptions = PhenixOptionBuilder.createRoomExpressOptions(with: pcastExpressOptions)
        roomExpress = PhenixRoomExpressFactory.createRoomExpress(roomExpressOptions)

        onlineStatusDisposable = roomExpress.pcastExpress
            .getObservableIsOnlineStatus()
            .subscribe(onlineStatusDidChange)
    }

    func makeMedia(completion: @escaping (UserMediaStreamController?) -> Void) {
        os_log(.debug, log: .phenixManager, "Start User Media Stream initialization")
        let options = PhenixUserMediaOptions.makeUserMediaOptions()
        roomExpress.pcastExpress.getUserMedia(options) { status, userMediaStream in
            if status == .ok, let stream = userMediaStream {
                os_log(.debug, log: .phenixManager, "User Media Stream initialized")

                let controller = UserMediaStreamController(stream)
                controller.subscribeForMediaFrameNotification()

                completion(controller)
                return
            }

            completion(nil)
        }
    }

    func processMedia() {
        dispatchPrecondition(condition: .onQueue(queue))

        // Using DispatchGroup to block the current execution thread.
        // It is necessary to always wait till the local media is retrieved,
        // because without it, we cannot connect and publish to any room.
        //
        // There could be a scenario where the user is in a room and the
        // device looses network connection, after it comes back online,
        // SDK could try to re-publish to the same room once again to
        // join it automatically, and to do that - user media stream is
        // necessary.
        // Before that happens SDK will always execute the PCast
        // „isOnlineStatus“ callback to let know about the new "online"
        // status. At that point app needs to retry to get new user
        // media stream. So it needs to block the execution queue and
        // wait for the async user media stream callback to return
        // the stream and initialize the user media stream controller,
        // which will be then used by the publisher.
        // If that is not done, there can be a race condition between
        // media retrieval and re-publishing, which will result in a
        // bad app state.

        var mediaController: UserMediaStreamController!

        // We need to always dispose and remove the existing user media
        // stream from the memory before we try to create a new media
        // stream. Right now Phenix SDK (v2021.0.1) does not allow
        // multiple simultaneous media streams, because they share some
        // facilities.
        // By not doing it like this, when first media stream will
        // get deallocated - it will also kill the second media stream.
        // This situation can be triggered by losing network connection
        // in an active room.
        userMediaStreamController?.dispose()
        userMediaStreamController = nil

        let group = DispatchGroup()
        group.enter()

        makeMedia { controller in
            mediaController = controller
            group.leave()
        }

        if group.wait(timeout: .now() + 30) == .timedOut {
            os_log(
                .debug,
                log: .phenixManager,
                "Could not retrieve user media stream before it reaches the timeout."
            )

            // Enable the possibility to create new media
            // stream, so that if it failed on the first
            // time right after application launch,
            // it can retry to create it again when online
            // status changes in future.
            enableMediaCreationOnOnlineStatusChange = true
            mediaCreationTimeoutHandler?()
            return
        }

        userMediaStreamController = mediaController
        userStreamMediaControllerDidChange(mediaController)
    }
}

// MARK: - Observable callback methods
private extension PhenixManager {
    func onlineStatusDidChange(_ changes: PhenixObservableChange<NSNumber>?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard let isOnline = changes?.value as? Bool else { return }

            os_log(.debug, log: .phenixManager, "Online status did change: %{PRIVATE}s", isOnline == true ? "online" : "offline")

            self.onlineStatusDidChange(isOnline: isOnline)

            guard isOnline == true else { return }

            // Do not try to create user media for the first time
            // when the "onlineStatusDidChange" is executed.
            // We are creating the media already in the
            // `func start(unrecoverableErrorCompletion:)` method
            // right after the PhenixRoomExpress is created.
            // PCastExpress executes this callback method
            // right after the PhenixRoomExpress gets created
            // if device meets the necessary conditions.
            // So that can result in a race condition for media
            // creation. To prevent that, we must ignore the
            // first time when this callback is executed and not
            // try to create the media once more.

            if self.enableMediaCreationOnOnlineStatusChange {
                self.processMedia()
            } else {
                // After first time "onlineStatusDidChange" is executed,
                // we can allow to generate new media on future
                // executions.
                self.enableMediaCreationOnOnlineStatusChange = true
            }
        }
    }
}

// MARK: - JoinedRoomDelegate
extension PhenixManager: JoinedRoomDelegate {
    func roomLeft(_ room: JoinedRoom) {
        queue.async { [weak self] in
            guard room == self?.joinedRoom else { return }

            self?.chatService?.dispose()
            self?.chatService = nil
            self?.set(room: nil)
        }
    }
}
