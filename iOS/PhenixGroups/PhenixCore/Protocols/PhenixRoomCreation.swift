//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

public enum PhenixRoomCreationError: Error {
    case failureStatus(PhenixRequestStatus)
}

public protocol PhenixRoomCreation: AnyObject {
    typealias RoomCreationHandler = (Result<PhenixImmutableRoom, PhenixRoomCreationError>) -> Void
    typealias RoomCreationAndJoiningHandler = (Result<PhenixRoom, PhenixRoomCreationError>) -> Void

    /// Creates new room
    /// - Parameters:
    ///   - alias: Room unique identifier
    ///   - completion: Handler which will be executed after processing room creation.
    func createRoom(withAlias alias: String, completion: @escaping RoomCreationHandler)
}

extension PhenixManager: PhenixRoomCreation {
    public func createRoom(withAlias alias: String = .randomRoomAlias, completion: @escaping RoomCreationHandler) {
        privateQueue.async { [weak self] in
            os_log(.debug, log: .phenixManager, "Creating a room with alias: %{PUBLIC}s", alias)

            guard let self = self else { return }
            let options = self.makeRoomOptions(with: alias)

            precondition(self.roomExpress != nil, "Must call PhenixManager.start() before this method")
            self.roomExpress.createRoom(options) { status, immutableRoom in
                os_log(.debug, log: .phenixManager, "Room creation completed with status: %{PUBLIC}d", status.rawValue)
                switch status {
                case .ok:
                    guard let immutableRoom = immutableRoom else {
                        fatalError("Could not get ImmutableRoom parameter")
                    }
                    completion(.success(immutableRoom))
                default:
                    completion(.failure(.failureStatus(status)))
                }
            }
        }
    }
}
