//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

public final class PhenixManager {
    public typealias UnrecoverableErrorHandler = (_ description: String?) -> Void

    /// Backend URL used by Phenix SDK to communicate
    internal let backend: URL
    internal let privateQueue: DispatchQueue

    internal private(set) var roomExpress: PhenixRoomExpress!
    internal private(set) var joinedRooms = Set<JoinedRoom>()

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
    public func start(unrecoverableErrorCompletion: UnrecoverableErrorHandler?) {
        let group = DispatchGroup()

        group.enter()
        os_log(.debug, log: .phenixManager, "Room Express setup started")
        setupRoomExpress(backend: backend, unrecoverableErrorCompletion) {
            os_log(.debug, log: .phenixManager, "Room Express setup completed")
            group.leave()
        }

        group.wait()

        group.enter()
        os_log(.debug, log: .phenixManager, "User Media Stream setup started")
        setupMedia(unrecoverableErrorCompletion) {
            os_log(.debug, log: .phenixManager, "User Media Stream setup completed")
            group.leave()
        }

        group.wait()
    }

    func add(_ room: JoinedRoom) {
        privateQueue.async { [weak self] in
            guard let self = self else { return }

            self.joinedRooms.insert(room)
            os_log(.debug, log: .phenixManager, "Joined room instance added")
        }
    }
}

private extension PhenixManager {
    func setupRoomExpress(backend: URL, _ unrecoverableErrorCompletion: UnrecoverableErrorHandler? = nil, completion: @escaping () -> Void) {
        let pcastExpressOptions = PhenixPCastExpressFactory.createPCastExpressOptionsBuilder()
            .withBackendUri(backend.absoluteString)
            .withUnrecoverableErrorCallback { _, description in
                os_log(.error, log: .phenixManager, "Unrecoverable Error: %{PUBLIC}@", String(describing: description))
                unrecoverableErrorCompletion?(description)
            }
            .buildPCastExpressOptions()

        let roomExpressOptions = PhenixRoomExpressFactory.createRoomExpressOptionsBuilder()
            .withPCastExpressOptions(pcastExpressOptions)
            .buildRoomExpressOptions()

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

extension PhenixManager: JoinedRoomDelegate {
    func roomLeft(_ room: JoinedRoom) {
        privateQueue.async { [weak self] in
            guard let self = self else { return }

            self.joinedRooms.remove(room)
            os_log(.debug, log: .phenixManager, "Joined room instance removed: %{PRIVATE}s", room.description)
        }
    }
}

// MARK: - Helper methods
internal extension PhenixManager {
    func makeRoomOptions(with alias: String) -> PhenixRoomOptions {
        PhenixRoomServiceFactory.createRoomOptionsBuilder()
            .withName(alias)
            .withAlias(alias)
            .withType(.multiPartyChat)
            .buildRoomOptions()
    }
}
