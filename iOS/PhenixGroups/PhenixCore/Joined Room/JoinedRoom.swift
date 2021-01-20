//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixChat
import PhenixSdk

internal protocol RoomRepresentation: AnyObject {
    var alias: String { get }
}

public class JoinedRoom: ChatProvider, RoomRepresentation {
    private weak var membersDelegate: JoinedRoomMembersDelegate?

    private let queue: DispatchQueue
    private let roomService: PhenixRoomService

    internal weak var delegate: JoinedRoomDelegate?

    public private(set) var media: RoomMediaController?
    public let memberController: RoomMemberController
    public let chatService: PhenixChatService
    public let backend: URL
    public var alias: String {
        roomService.getObservableActiveRoom()?.getValue()?.getObservableAlias()?.getValue() as String? ?? "N/A"
    }

    init(roomExpress: PhenixRoomExpress, backend: URL, roomService: PhenixRoomService, chatService: PhenixChatService, queue: DispatchQueue, publisher: PhenixExpressPublisher? = nil, userMedia: UserMediaProvider? = nil) {
        self.backend = backend
        self.roomService = roomService
        self.chatService = chatService
        self.queue = queue

        if let publisher = publisher {
            self.media = RoomMediaController(publisher: publisher, queue: queue)
        }

        self.memberController = RoomMemberController(roomService: roomService, roomExpress: roomExpress, queue: queue, userMedia: userMedia)
        self.memberController.roomRepresentation = self

        self.media?.roomRepresentation = self
    }

    /// Clears all room disposables and all member subscriptions
    ///
    /// Must be called when SDK automatically re-publishes to the room, also if user didn't left the room manually.
    internal func dispose() {
        queue.sync { [weak self] in
            guard let self = self else { return }
            os_log(.debug, log: .joinedRoom, "Dispose, (%{PRIVATE}s)", self.description)

            self.chatService.dispose()
            self.memberController.dispose()
        }
    }

    /// Clears all room disposables and all member subscriptions, stops publishing and leaves the room with SDK method
    public func leave() {
        queue.sync { [weak self] in
            guard let self = self else { return }
            os_log(.debug, log: .joinedRoom, "Leave joined room, (%{PRIVATE}s)", self.description)

            self.chatService.dispose()
            self.memberController.dispose()

            self.media?.stop()

            self.roomService.leaveRoom { _, _ in
                os_log(.debug, log: .joinedRoom, "Joined room left, (%{PRIVATE}s)", self.description)
                self.delegate?.roomLeft(self)
            }
        }
    }
}

// MARK: - CustomStringConvertible
extension JoinedRoom: CustomStringConvertible {
    public var description: String {
        "Joined Room, backend: \(backend.absoluteURL), alias: \(alias))"
    }
}

// MARK: - Hashable
extension JoinedRoom: Hashable {
    public static func == (lhs: JoinedRoom, rhs: JoinedRoom) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
