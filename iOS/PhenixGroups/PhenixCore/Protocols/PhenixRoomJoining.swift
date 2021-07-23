//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

public enum RoomIdentifierType: CustomStringConvertible {
    case identifier(_ id: String)
    case alias(_ alias: String)

    public var description: String {
        switch self {
        case .identifier(let id):
            return "Identifier (\(id)"
        case .alias(let alias):
            return "Alias (\(alias)"
        }
    }
}

public enum PhenixRoomJoiningError: Error {
    case failureStatus(PhenixRequestStatus)
}

public protocol PhenixRoomJoining: AnyObject {
    typealias JoinRoomHandler = (Result<JoinedRoom, PhenixRoomJoiningError>) -> Void

    /// Join already created room
    /// - Parameters:
    ///   - type: Provide room alias or identifier
    ///   - displayName: User public display name
    ///   - completion: Handler which will be executed after joining the room
    func joinRoom(with type: RoomIdentifierType, displayName: String, completion: @escaping JoinRoomHandler)
}

extension PhenixManager: PhenixRoomJoining {
    public func joinRoom(with type: RoomIdentifierType, displayName: String, completion: @escaping JoinRoomHandler) {
        queue.async { [weak self] in
            os_log(.debug, log: .phenixManager, "Joining a room with %{PRIVATE}s, display name: %{PRIVATE}s", type.description, displayName)
            guard let self = self else { return }
            let options: PhenixJoinRoomOptions

            switch type {
            case .identifier(let id):
                options = PhenixOptionBuilder.createJoinRoomOptions(id: id, displayName: displayName)

            case .alias(let alias):
                options = PhenixOptionBuilder.createJoinRoomOptions(alias: alias, displayName: displayName)
            }

            self.joinRoom(with: options, completion: completion)
        }
    }
}

extension PhenixManager {
    private func joinRoom(with options: PhenixJoinRoomOptions, completion: @escaping JoinRoomHandler) {
        dispatchPrecondition(condition: .onQueue(queue))
        precondition(self.roomExpress != nil, "Must call PhenixManager.start() before this method")
        self.roomExpress.joinRoom(options) { [weak self] status, roomService in
            guard let self = self else { return }
            self.queue.async {
                os_log(.debug, log: .phenixManager, "Room joining completed with status: %{PUBLIC}d", status.rawValue)
                switch status {
                case .ok:
                    guard let roomService = roomService else {
                        fatalError("PhenixRoomService not provided.")
                    }

                    // Clear existing room
                    self.disposeCurrentlyJoinedRoom()

                    // Make new room
                    let joinedRoom = self.makeJoinedRoom(
                        roomExpress: self.roomExpress,
                        roomService: roomService,
                        backend: self.backend
                    )

                    // Save new room
                    self.set(room: joinedRoom)

                    completion(.success(joinedRoom))

                default:
                    completion(.failure(.failureStatus(status)))
                }
            }
        }
    }
}
