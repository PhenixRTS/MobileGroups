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

            os_log(.debug, log: .phenixManager, "Publishing to a room with alias: %{PUBLIC}@, display name: %{PUBLIC}@", alias, displayName)
            let roomOptions = self.makeRoomOptions(with: alias)
            let publishOptions = self.makePublishOptions()
            let localPublishToRoomOptions = self.makeLocalPublishToRoomOptions(displayName: displayName, roomOptions: roomOptions, publishOptions: publishOptions)

            precondition(self.roomExpress != nil, "Must call PhenixManager.start() before this method")
            self.roomExpress.publish(toRoom: localPublishToRoomOptions) { status, roomService, _ in
                os_log(.debug, log: .phenixManager, "Room publishing completed with status: %{PUBLIC}d", status.rawValue)
                switch status {
                case .ok:
                    guard let roomService = roomService else {
                        fatalError("Could not get RoomService parameter")
                    }

                    let joinedRoom = JoinedRoom(backend: self.backend, roomService: roomService)
                    joinedRoom.delegate = self
                    self.add(joinedRoom)

                    completion(.success(joinedRoom))

                default:
                    completion(.failure(.failureStatus(status)))
                }
            }
        }
    }
}

// MARK: - Helpers

private extension PhenixManager {
    func makePublishOptions() -> PhenixPublishOptions {
        PhenixPCastExpressFactory.createPublishOptionsBuilder()
            .withUserMedia(self.userMediaStreamController.userMediaStream)
            .withCapabilities(PhenixConfiguration.capabilities)
            .buildPublishOptions()
    }

    func makeLocalPublishToRoomOptions(displayName: String, roomOptions: PhenixRoomOptions, publishOptions: PhenixPublishOptions) -> PhenixPublishToRoomOptions {
        PhenixRoomExpressFactory.createPublishToRoomOptionsBuilder()
            .withRoomOptions(roomOptions)
            .withPublishOptions(publishOptions)
            .withScreenName(displayName)
            .buildPublishToRoomOptions()
    }
}
