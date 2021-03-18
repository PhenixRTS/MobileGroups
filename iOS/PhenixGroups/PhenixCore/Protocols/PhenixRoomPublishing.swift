//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

public enum PhenixRoomPublishingError: Error {
    case failureStatus(PhenixRequestStatus)
    case noMediaAvailable
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
    // swiftlint:disable closure_body_length
    public func publishRoom(withAlias alias: String, displayName: String, completion: @escaping RoomPublishHandler) {
        queue.async { [weak self] in
            guard let self = self else { return }

            guard let media = self.userMediaStreamController else {
                completion(.failure(.noMediaAvailable))
                return
            }

            os_log(.debug, log: .phenixManager, "Publishing to a room with alias: %{PRIVATE}s, display name: %{PRIVATE}s", alias, displayName)
            let roomOptions = PhenixOptionBuilder.createRoomOptions(alias: alias)
            let publishOptions = PhenixOptionBuilder.createPublishOptions(with: media.userMediaStream)
            let localPublishToRoomOptions = PhenixOptionBuilder.createPublishToRoomOptions(with: roomOptions, publishOptions: publishOptions, displayName: displayName)

            precondition(self.roomExpress != nil, "Must call PhenixManager.start() before this method")
            self.roomExpress.publish(toRoom: localPublishToRoomOptions) { status, roomService, publisher in
                self.queue.async {
                    os_log(.debug, log: .phenixManager, "Room publishing completed with status: %{PUBLIC}s", status.description)
                    switch status {
                    case .ok:
                        guard let roomService = roomService else {
                            fatalError("PhenixRoomService not provided.")
                        }

                        guard let publisher = publisher else {
                            fatalError("PhenixExpressPublisher not provided.")
                        }

                        // Clear existing room
                        self.disposeCurrentlyJoinedRoom()

                        // Make new room
                        let joinedRoom = self.makeJoinedRoom(
                            roomExpress: self.roomExpress,
                            roomService: roomService,
                            backend: self.backend,
                            publisher: publisher,
                            userMedia: media
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
}
