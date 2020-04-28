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

    /// Creates new room and automatically joins it
    /// - Parameters:
    ///   - alias: Room unique identifier
    ///   - displayName: User public display name
    ///   - completion: Handler which will be executed after processing room creation.
    func createAndJoinRoom(withAlias alias: String, displayName: String, completion: @escaping RoomCreationAndJoiningHandler)
}

extension PhenixManager: PhenixRoomCreation {
    public func createRoom(withAlias alias: String = .randomRoomAlias, completion: @escaping RoomCreationHandler) {
        privateQueue.async { [weak self] in
            os_log(.debug, log: .phenixManager, "Creating a room with alias: %{PUBLIC}@", alias)

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

    public func createAndJoinRoom(withAlias alias: String, displayName: String, completion: @escaping RoomCreationAndJoiningHandler) {
        privateQueue.async { [weak self] in
            os_log(.debug, log: .phenixManager, "Creating a room with alias: %{PUBLIC}@ and automatically joining with display name: %{PUBLIC}@", alias, displayName)

            guard let self = self else { return }
            let roomOptions = self.makeRoomOptions(with: alias)
            let publishOptions = self.makePublishOptions()

            let localPublishToRoomOptions = PhenixRoomExpressFactory.createPublishToRoomOptionsBuilder()
                .withRoomOptions(roomOptions)
                .withPublishOptions(publishOptions)
                .withScreenName(displayName)
                .buildPublishToRoomOptions()

            precondition(self.roomExpress != nil, "Must call PhenixManager.start() before this method")
            self.roomExpress.publish(toRoom: localPublishToRoomOptions) { status, roomService, _ in
                os_log(.debug, log: .phenixManager, "Room publishing completed with status: %{PUBLIC}d", status.rawValue)
                self.joinedRoomService = roomService
                switch status {
                case .ok:
                    guard let room = roomService?.getObservableActiveRoom()?.getValue() else {
                        fatalError("Could not get RoomService parameters")
                    }
                    completion(.success(room))
                default:
                    completion(.failure(.failureStatus(status)))
                }
            }
        }
    }
}

// MARK: - Helper methods

extension PhenixManager {
    private func makePublishOptions() -> PhenixPublishOptions {
        #warning("Use User Media stream")
        return PhenixPCastExpressFactory.createPublishOptionsBuilder()
            //.withUserMedia(PhenixUserMediaStream)
            .withCapabilities(PhenixConfiguration.capabilities)
            .buildPublishOptions()
    }

    private func makeRoomOptions(with alias: String) -> PhenixRoomOptions {
        PhenixRoomServiceFactory.createRoomOptionsBuilder()
            .withName(alias)
            .withAlias(alias)
            .withType(.multiPartyChat)
            .buildRoomOptions()
    }
}
