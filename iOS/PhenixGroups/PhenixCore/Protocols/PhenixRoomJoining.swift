//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
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
        privateQueue.async { [weak self] in
            os_log(.debug, log: .phenixManager, "Joining a room with %{PUBLIC}s, display name: %{PUBLIC}s", type.description, displayName)
            guard let self = self else { return }
            let options: PhenixJoinRoomOptions

            switch type {
            case .identifier(let id):
                options = PhenixRoomExpressFactory.createJoinRoomOptionsBuilder()
                    .withRoomId(id)
                    .withScreenName(displayName)
                    .buildJoinRoomOptions()

            case .alias(let alias):
                options = PhenixRoomExpressFactory.createJoinRoomOptionsBuilder()
                    .withRoomAlias(alias)
                    .withScreenName(displayName)
                    .buildJoinRoomOptions()
            }

            self.joinRoom(with: options, completion: completion)
        }
    }
}

extension PhenixManager {
    private func joinRoom(with options: PhenixJoinRoomOptions, completion: @escaping JoinRoomHandler) {
        dispatchPrecondition(condition: .onQueue(privateQueue))
        precondition(self.roomExpress != nil, "Must call PhenixManager.start() before this method")
        self.roomExpress.joinRoom(options) { [weak self] status, roomService in
            guard let self = self else { return }
            os_log(.debug, log: .phenixManager, "Joining a room completed with status: %{PUBLIC}d", status.rawValue)
            switch status {
            case .ok:
                guard let roomService = roomService else {
                    fatalError("Could not get RoomService parameter")
                }

                // Chat service must be created with a small delay after the Room service was created.
                // There is a possibility that if they are created shortly one after another - chat history may not be found.
                // Therefore JoinedRoom creation is done after a small delay.
                self.privateQueue.asyncAfter(deadline: .now() + .seconds(1)) {
                    let joinedRoom = self.makeJoinedRoom(from: roomService, roomExpress: self.roomExpress, backend: self.backend)
                    self.add(joinedRoom)
                    completion(.success(joinedRoom))
                }

            default:
                completion(.failure(.failureStatus(status)))
            }
        }
    }
}
