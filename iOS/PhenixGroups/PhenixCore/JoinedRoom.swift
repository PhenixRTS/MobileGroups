//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import PhenixSdk

protocol JoinedRoomDelegate: AnyObject {
    func roomLeft(_ room: JoinedRoom)
}

public class JoinedRoom {
    public let backend: URL
    public var alias: String? {
        roomService.getObservableActiveRoom()?.getValue()?.getObservableAlias()?.getValue() as String?
    }

    weak var delegate: JoinedRoomDelegate?

    private var roomService: PhenixRoomService

    init(backend: URL, roomService: PhenixRoomService) {
        self.backend = backend
        self.roomService = roomService
    }

    public func leave() {
        roomService.leaveRoom { [weak self] _, _ in
            guard let self = self else { return }
            self.delegate?.roomLeft(self)
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
