//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

protocol JoinedRoomDelegate: AnyObject {
    func roomLeft(_ room: JoinedRoom)
}

public class JoinedRoom: CustomStringConvertible {
    public let backend: URL
    public var alias: String? {
        roomService.getObservableActiveRoom()?.getValue()?.getObservableAlias()?.getValue() as String?
    }

    weak var delegate: JoinedRoomDelegate?

    private let roomService: PhenixRoomService
    private let publisher: PhenixExpressPublisher?

    public var description: String {
        "Joined Room, backend: \(backend.absoluteURL), alias: \(String(describing: alias))"
    }

    init(backend: URL, roomService: PhenixRoomService, publisher: PhenixExpressPublisher? = nil) {
        self.backend = backend
        self.roomService = roomService
        self.publisher = publisher
    }

    public func leave() {
        os_log(.debug, log: .joinedRoom, "Leaving joined room %{PRIVATE}s", self.description)
        publisher?.stop()
        roomService.leaveRoom { [weak self] _, _ in
            guard let self = self else { return }
            self.delegate?.roomLeft(self)
            os_log(.debug, log: .joinedRoom, "Left joined room %{PRIVATE}s", self.description)
        }
    }

    public func setAudio(enabled: Bool) {
        os_log(.debug, log: .joinedRoom, "Set Publisher audio enabled - %{PUBLIC}d", enabled)

        if enabled {
            publisher?.enableAudio()
        } else {
            publisher?.disableAudio()
        }
    }

    public func setVideo(enabled: Bool) {
        os_log(.debug, log: .joinedRoom, "Set Publisher video enabled - %{PUBLIC}d", enabled)

        if enabled {
            publisher?.enableVideo()
        } else {
            publisher?.disableVideo()
        }
    }
}

extension JoinedRoom: Hashable {
    public static func == (lhs: JoinedRoom, rhs: JoinedRoom) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
