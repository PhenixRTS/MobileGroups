//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

public final class PhenixManager {
    public typealias UnrecoverableErrorHandler = (_ description: String?) -> Void

    private var joinedRoom: JoinedRoom?
    private var chatService: PhenixRoomChatService?

    /// Backend URL used by Phenix SDK to communicate
    internal let backend: URL
    internal let privateQueue: DispatchQueue
    internal private(set) var roomExpress: PhenixRoomExpress!

    public private(set) var userMediaStreamController: UserMediaStreamController!

    /// Initializer for Phenix manager
    /// - Parameter backend: Backend URL for Phenix SDK
    public convenience init(backend: URL) {
        let privateQueue = DispatchQueue(label: "com.phenixrts.suite.groups.core.PhenixManager")
        self.init(backend: backend, privateQueue: privateQueue)
    }

    /// Initializer for internal tests
    /// - Parameters:
    ///   - backend: Backend URL for Phenix SDK
    ///   - privateQueue: Private queue used for making manager thread safe and possible to run on background threads
    internal init(backend: URL, privateQueue: DispatchQueue) {
        self.privateQueue = privateQueue
        self.backend = backend
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

    func set(_ room: JoinedRoom) {
        privateQueue.async { [weak self] in
            guard let self = self else { return }
            os_log(.debug, log: .phenixManager, "Destroy previous joined room instance")
            self.joinedRoom?.destroy()
            os_log(.debug, log: .phenixManager, "Set new joined room instance")
            self.joinedRoom = room
        }
    }
}

// MARK: - Setup methods
private extension PhenixManager {
    func setupRoomExpress(backend: URL, _ unrecoverableErrorCompletion: @escaping UnrecoverableErrorHandler, completion: @escaping () -> Void) {
        let pcastExpressOptions = PhenixOptionBuilder.createPCastExpressOptions(backend: backend, unrecoverableErrorCallback: unrecoverableErrorCompletion)
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

// MARK: - Helper methods
internal extension PhenixManager {
    func makeJoinedRoom(from roomService: PhenixRoomService, roomExpress: PhenixRoomExpress, backend: URL, publisher: PhenixExpressPublisher? = nil) -> JoinedRoom {
        dispatchPrecondition(condition: .notOnQueue(.main))
        let queue = DispatchQueue(label: "com.phenixrts.suite.groups.core.JoinedRoom", qos: .userInitiated, target: privateQueue)
        // Re-use the same chat service or create a new one if the room was left previously.
        let chatService: PhenixRoomChatService = self.chatService ?? PhenixRoomChatServiceFactory.createRoomChatService(roomService)
        let joinedRoom = JoinedRoom(roomExpress: roomExpress, backend: backend, roomService: roomService, chatService: chatService, queue: queue, publisher: publisher)
        joinedRoom.delegate = self

        return joinedRoom
    }
}

// MARK: - JoinedRoomDelegate
extension PhenixManager: JoinedRoomDelegate {
    func roomLeft(_ room: JoinedRoom) {
        privateQueue.async { [weak self] in
            self?.chatService = nil
            self?.joinedRoom = nil
            os_log(.debug, log: .phenixManager, "Joined room instance removed: %{PRIVATE}s", room.description)
        }
    }
}
