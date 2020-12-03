//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixSdk

protocol RoomMemberControllerDelegate: AnyObject {
    func canSubscribeWithVideo() -> Bool
}

public class RoomMemberController {
    private static let maxVideoSubscriptions = 3

    private weak var roomService: PhenixRoomService?
    private weak var roomExpress: PhenixRoomExpress?
    private let queue: DispatchQueue
    private var memberListDisposable: PhenixDisposable?
    private var members: Set<RoomMember>

    internal weak var roomRepresentation: RoomRepresentation?

    public let currentMember: RoomMember
    public weak var delegate: JoinedRoomMembersDelegate?

    init(roomService: PhenixRoomService, roomExpress: PhenixRoomExpress, queue: DispatchQueue = .main, roomRepresentation: RoomRepresentation? = nil) {
        self.roomService = roomService
        self.roomExpress = roomExpress
        self.roomRepresentation = roomRepresentation
        self.queue = queue

        self.currentMember = RoomMember(roomService.getSelf(), isSelf: true, roomExpress: roomExpress, queue: queue)
        self.members = []
    }

    public func subscribeToMemberList() {
        os_log(.debug, log: .memberController, "Subscribe to room member list updates, (%{PRIVATE}s)", roomDescription)
        memberListDisposable = roomService?.getObservableActiveRoom()?.getValue()?.getObservableMembers()?.subscribe(memberListDidChange)
    }
}

// MARK: - Internal methods
internal extension RoomMemberController {
    func dispose() {
        memberListDisposable = nil
        members.forEach { $0.dispose() }
    }
}

// MARK: - Private methods
private extension RoomMemberController {
    var roomDescription: String { roomRepresentation?.alias ?? "-" }

    /// Proceed newly received member list
    /// - Parameter members: Phenix member list
    func processLatestMembers(_ members: [PhenixMember]) {
        dispatchPrecondition(condition: .onQueue(queue))

        // Convert PhenixMember array to RoomMember array.
        let roomMembers = members.map(makeRoomMember)

        // Convert RoomMember array to a Set
        let newMembers = Set(roomMembers)

        // Compare the new list of members with the old list of members.
        let memberListDidChange = process(
            newMembers: newMembers,
            oldMembers: self.members,
            connectedMemberHandler: membersConnected,
            disconnectedMemberHandler: membersDisconnected
        )

        // If there are changes in the members array, notify the delegate about that.
        if memberListDidChange {
            let memberList = roomMembers.sorted()
            delegate?.memberListDidChange(memberList)
        }
    }

    /// Find out, did the members list has changes inside it
    ///
    /// Searches the members list for newly connected members and for disconnected members.
    /// - Parameters:
    ///   - newMembers: Received member list
    ///   - oldMembers: Current member list
    ///   - connectedMemberHandler: Closure for handling members, if there are any who just now connected.
    ///   - disconnectedMemberHandler: Closure for handling members, if there are any who just now disconnected.
    /// - Returns: Provides `true` if there were some changes in the member list
    func process(newMembers: Set<RoomMember>, oldMembers: Set<RoomMember>, connectedMemberHandler: (Set<RoomMember>) -> Void, disconnectedMemberHandler: (Set<RoomMember>) -> Void) -> Bool {
        dispatchPrecondition(condition: .onQueue(queue))

        // Get list of elements which does not exist in updatedMemberList but exist in currentMemberList, in simple words, members who left.
        let disconnectedMembers = oldMembers.subtracting(newMembers)
        disconnectedMemberHandler(disconnectedMembers)

        // Get list of elements which does no.
        let connectedMembers = newMembers.subtracting(oldMembers)
        connectedMemberHandler(connectedMembers)

        // Check if the member list did change at all.
        let memberListDidChange = disconnectedMembers.isEmpty == false || connectedMembers.isEmpty == false

        return memberListDidChange
    }

    func membersConnected(_ newMembers: Set<RoomMember>) {
        dispatchPrecondition(condition: .onQueue(queue))

        guard newMembers.isEmpty == false else { return }

        members.formUnion(newMembers)
        os_log(.debug, log: .memberController, "Members connected to the room: %{PRIVATE}s", newMembers.description)

        for member in newMembers {
            // Observe new member stream and then automatically subscribe to it
            member.roomController = self
            member.observeStreams()
        }
    }

    func membersDisconnected(_ oldMembers: Set<RoomMember>) {
        dispatchPrecondition(condition: .onQueue(queue))

        guard oldMembers.isEmpty == false else { return }

        os_log(.debug, log: .memberController, "Members disconnected from the room: %{PRIVATE}s", oldMembers.description)
        members.subtract(oldMembers)

        for member in oldMembers {
            member.dispose()
        }
    }

    func makeRoomMember(_ member: PhenixMember) -> RoomMember {
        dispatchPrecondition(condition: .onQueue(queue))

        guard let roomExpress = roomExpress else {
            fatalError("Room Express must be provided")
        }

        if member == currentMember {
            return currentMember
        } else {
            return RoomMember(member, isSelf: false, roomExpress: roomExpress, queue: queue)
        }
    }
}

// MARK: - RoomMemberControllerDelegate
extension RoomMemberController: RoomMemberControllerDelegate {
    func canSubscribeWithVideo() -> Bool {
        // Calculate, how many of members have video subscription at the moment.
        let videoSubscriptions = members.reduce(into: 0) { result, member in
            result += member.subscriptionType == .some(.video) ? 1 : 0
        }

        if videoSubscriptions + 1 <= Self.maxVideoSubscriptions {
            return true
        } else {
            return false
        }
    }
}

// MARK: - Observable callback methods
private extension RoomMemberController {
    func memberListDidChange(_ changes: PhenixObservableChange<NSArray>?) {
        queue.async { [weak self] in
            guard let members = changes?.value as? [PhenixMember] else { return }

            self?.processLatestMembers(members)
        }
    }
}

// MARK: - Sequence where Element == RoomMember
fileprivate extension Sequence where Element == RoomMember {
    /// Sort `RoomMember` list in a way that the `Self` member always will be first
    /// - Returns: Sorted `RoomMember` list
    func sorted() -> [Self.Element] {
        self.sorted { lhs, rhs -> Bool in
            if lhs.isSelf {
                return true
            } else if rhs.isSelf {
                return false
            }

            return lhs > rhs
        }
    }
}
