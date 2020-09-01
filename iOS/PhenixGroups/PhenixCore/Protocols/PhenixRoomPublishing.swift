//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

public enum PhenixRoomPublishingError: Error {
    case failureStatus(PhenixRequestStatus)
}

public protocol PhenixRoomPublishing: AnyObject {
    typealias RoomPublishHandler = (Result<JoinedRoom, PhenixRoomPublishingError>) -> Void

    /// Joins existing room or crates a new room and then joins it, also publishes local media
    /// - Parameters:
    ///   - alias: Room unique identifier
    ///   - displayName: User public display name
    ///   - completion: Handler which will be executed after processing room creation.
    func publishRoom(withAlias alias: String, displayName: String, completion: @escaping RoomPublishHandler)
}

extension PhenixManager: PhenixRoomPublishing {
    public func publishRoom(withAlias alias: String, displayName: String, completion: @escaping RoomPublishHandler) {
        privateQueue.async { [weak self] in
            guard let self = self else { return }

            os_log(.debug, log: .phenixManager, "Publishing to a room with alias: %{PUBLIC}s, display name: %{PUBLIC}s", alias, displayName)
            let roomOptions = PhenixOptionBuilder.createRoomOptions(alias: alias)
            let publishOptions = PhenixOptionBuilder.createPublishOptions(with: self.userMediaStreamController.userMediaStream)
            let localPublishToRoomOptions = PhenixOptionBuilder.createPublishToRoomOptions(with: roomOptions, publishOptions: publishOptions, displayName: displayName)

            precondition(self.roomExpress != nil, "Must call PhenixManager.start() before this method")
            self.roomExpress.publish(toRoom: localPublishToRoomOptions) { status, roomService, publisher in
                os_log(.debug, log: .phenixManager, "Room publishing completed with status: %{PUBLIC}d", status.rawValue)
                switch status {
                case .ok:
                    guard let roomService = roomService else {
                        fatalError("Could not get RoomService parameter")
                    }

                    guard let publisher = publisher else {
                        fatalError("Could not get Publisher parameter")
                    }

                    // Chat service must be created with a small delay after the Room service was created.
                    // There is a possibility that if they are created shortly one after another - chat history may not be found.
                    // Therefore JoinedRoom creation is done after a small delay.
                    self.privateQueue.asyncAfter(deadline: .now() + .seconds(1)) {
                        let joinedRoom = self.makeJoinedRoom(from: roomService, roomExpress: self.roomExpress, backend: self.backend, publisher: publisher)
                        self.set(joinedRoom)
                        completion(.success(joinedRoom))
                    }

                default:
                    completion(.failure(.failureStatus(status)))
                }
            }
        }
    }
}
