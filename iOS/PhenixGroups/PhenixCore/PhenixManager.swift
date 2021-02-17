//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixChat
import PhenixSdk

public final class PhenixManager {
    public typealias UnrecoverableErrorHandler = (_ description: String?) -> Void

    private var joinedRoom: JoinedRoom?
    private var chatService: PhenixChatService?

    internal let queue: DispatchQueue
    internal private(set) var roomExpress: PhenixRoomExpress!

    /// Backend URL used by Phenix SDK to communicate
    public let backend: URL
    public let pcast: URL?
    /// Maximum allowed member count with video subscription at the same time.
    public let maxVideoSubscriptions: Int
    public private(set) var userMediaStreamController: UserMediaStreamController!

    /// Initializer for Phenix manager
    /// - Parameter backend: Backend URL for Phenix SDK
    public init(backend: URL, pcast: URL?, maxVideoSubscriptions: Int = 4) {
        self.pcast = pcast
        self.queue = DispatchQueue(label: "com.phenixrts.suite.groups.core.PhenixManager")
        self.backend = backend
        self.maxVideoSubscriptions = maxVideoSubscriptions
    }

    /// Creates necessary instances of PhenixSdk which provides connection and media streaming possibilities
    ///
    /// Method needs to be executed before trying to create or join rooms.
    public func start(unrecoverableErrorCompletion: @escaping UnrecoverableErrorHandler) {
        let group = DispatchGroup()

        group.enter()
        os_log(.debug, log: .phenixManager, "Start Room Express setup")
        setupRoomExpress(backend: backend, unrecoverableErrorCompletion) {
            os_log(.debug, log: .phenixManager, "Room Express setup completed")
            group.leave()
        }

        group.wait()

        group.enter()
        os_log(.debug, log: .phenixManager, "Start User Media Stream setup")
        setupMedia(unrecoverableErrorCompletion) {
            os_log(.debug, log: .phenixManager, "User Media Stream setup completed")
            group.leave()
        }

        group.wait()
    }
}

// MARK: - Helper methods
internal extension PhenixManager {
    func set(room: JoinedRoom) {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(.debug, log: .phenixManager, "Set new joined room instance")
        joinedRoom = room
    }

    func makeJoinedRoom(roomService: PhenixRoomService, roomExpress: PhenixRoomExpress, backend: URL, publisher: PhenixExpressPublisher? = nil, userMedia: UserMediaProvider? = nil) -> JoinedRoom {
        dispatchPrecondition(condition: .onQueue(queue))

        let queue = DispatchQueue(label: "com.phenixrts.suite.groups.core.JoinedRoom", qos: .userInitiated)

        // Re-use the same chat service or create a new one if the room was left previously.
        let chatService: PhenixChatService = self.chatService ?? PhenixChatService(roomService: roomService)

        // Save chat service if it don't exist already.
        if self.chatService == nil {
            os_log(.debug, log: .phenixManager, "Chat service does not exist, create a new one")
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
            maxVideoSubscriptions: maxVideoSubscriptions,
            queue: queue,
            userMedia: userMedia
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
    func setupRoomExpress(backend: URL, _ unrecoverableErrorCompletion: @escaping UnrecoverableErrorHandler, completion: @escaping () -> Void) {
        let pcastExpressOptions = PhenixOptionBuilder.createPCastExpressOptions(backend: backend, pcast: pcast, unrecoverableErrorCallback: unrecoverableErrorCompletion)
        let roomExpressOptions = PhenixOptionBuilder.createRoomExpressOptions(with: pcastExpressOptions)

        #warning("Remove async quick-fix when Room Express will be thread safe.")
        DispatchQueue.main.async {
            self.roomExpress = PhenixRoomExpressFactory.createRoomExpress(roomExpressOptions)
            os_log(.debug, log: .phenixManager, "Room Express initialized")

            completion()
        }
    }

    func setupMedia(_ unrecoverableErrorCompletion: UnrecoverableErrorHandler? = nil, completion: @escaping () -> Void) {
        let options = PhenixUserMediaOptions.makeUserMediaOptions()
        roomExpress.pcastExpress.getUserMedia(options) { [weak self] status, userMediaStream in
            guard let self = self else { return }

            if status == .ok {
                if let stream = userMediaStream {
                    self.userMediaStreamController = UserMediaStreamController(stream)
                    os_log(.debug, log: .phenixManager, "User Media Stream initialized")
                    completion()
                    return
                }
            }

            unrecoverableErrorCompletion?("Could not provide user media stream (\(status.rawValue)")
        }
    }
}

// MARK: - JoinedRoomDelegate
extension PhenixManager: JoinedRoomDelegate {
    func roomLeft(_ room: JoinedRoom) {
        queue.async { [weak self] in
            self?.chatService?.dispose()
            self?.chatService = nil
            self?.joinedRoom = nil
            os_log(.debug, log: .phenixManager, "Joined room instance removed: %{PRIVATE}s", room.description)
        }
    }
}
