//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

public final class PhenixManager {
    /// Backend URL used by Phenix SDK to communicate
    internal let backend: URL
    internal let privateQueue: DispatchQueue

    internal private(set) var roomExpress: PhenixRoomExpress!
    internal var joinedRoomService: PhenixRoomService?

    /// Initializer for Phenix manager
    /// - Parameter backend: Backend URL for Phenix SDK
    public convenience init(backend: URL) {
        let privateQueue = DispatchQueue.main
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
    /// It is thread-safe.
    public func start(unrecoverableErrorCompletion: ((_ description: String?) -> Void)?) {
        privateQueue.async { [unowned self] in
            let pcastExpressOptions = PhenixPCastExpressFactory.createPCastExpressOptionsBuilder()
                .withBackendUri(self.backend.absoluteString)
                .withUnrecoverableErrorCallback { _, description in
                    os_log(.error, log: .phenixManager, "Unrecoverable Error: %{PUBLIC}@", String(describing: description))
                    unrecoverableErrorCompletion?(description)
                }
                .buildPCastExpressOptions()

            let roomExpressOptions = PhenixRoomExpressFactory.createRoomExpressOptionsBuilder()
                .withPCastExpressOptions(pcastExpressOptions)
                .buildRoomExpressOptions()

            dispatchPrecondition(condition: .onQueue(.main)) // RoomExpress creation must always be executed from the main thread
            self.roomExpress = PhenixRoomExpressFactory.createRoomExpress(roomExpressOptions)
            os_log(.debug, log: .phenixManager, "Room Express initialized")
        }
    }
}
