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

    public let backend: URL
    public let chatService: PhenixChatService
    public let mediaController: RoomMediaController?
    public let memberController: RoomMemberController
    public var alias: String {
        roomService.getObservableActiveRoom()?.getValue()?.getObservableAlias()?.getValue() as String? ?? "N/A"
    }

    init(
        roomService: PhenixRoomService,
        chatService: PhenixChatService,
        mediaController: RoomMediaController?,
        memberController: RoomMemberController,
        backend: URL,
        queue: DispatchQueue
    ) {
        self.queue = queue
        self.mediaController = mediaController
        self.backend = backend
        self.roomService = roomService
        self.chatService = chatService
        self.memberController = memberController
    }

    /// Clears all room disposables and all member subscriptions, stops publishing and leaves the room.
    public func leave() {
        queue.sync {
            os_log(.debug, log: .joinedRoom, "Leave joined room, (%{PRIVATE}s)", self.description)

            self.chatService.dispose()
            self.memberController.dispose()

            self.mediaController?.stop()

            self.roomService.leaveRoom { [weak self] _, _ in
                guard let self = self else { return }
                os_log(.debug, log: .joinedRoom, "Joined room left, (%{PRIVATE}s)", self.description)
                self.delegate?.roomLeft(self)
            }
        }
    }
}

// MARK: - Internal methods
internal extension JoinedRoom {
    /// Clears all room disposables and all member subscriptions.
    ///
    /// Must be called when SDK automatically re-publishes to the room, also if user didn't left the room manually.
    func dispose() {
        dispatchPrecondition(condition: .onQueue(queue))
        os_log(.debug, log: .joinedRoom, "Dispose, (%{PRIVATE}s)", description)

        chatService.dispose()
        memberController.dispose()
    }
}

// MARK: - CustomStringConvertible
extension JoinedRoom: CustomStringConvertible {
    public var description: String {
        "Joined Room, backend: \(backend.absoluteURL), alias: \(alias)"
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
