//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixSdk

protocol RoomMemberControllerDelegate: AnyObject {
    func canSubscribeForVideo() -> Bool
}

public class RoomMemberController {
    private weak var roomService: PhenixRoomService?
    private weak var roomExpress: PhenixRoomExpress?

    private let queue: DispatchQueue
    private var memberListDisposable: PhenixDisposable?
    private var members: Set<RoomMember> {
        didSet { membersListDidChange(members) }
    }

    internal weak var roomRepresentation: RoomRepresentation?

    /// Maximum allowed member count with video subscription at the same time.
    public let maxVideoSubscriptions: Int
    public let currentMember: RoomMember
    public weak var delegate: JoinedRoomMembersDelegate?

    init(
        roomService: PhenixRoomService,
        roomExpress: PhenixRoomExpress,
        userMedia: UserMediaProvider?,
        maxVideoSubscriptions: Int,
        queue: DispatchQueue = .main
    ) {
        self.queue = queue
        self.roomService = roomService
        self.roomExpress = roomExpress
        self.maxVideoSubscriptions = maxVideoSubscriptions

        self.currentMember = RoomMember(
            localMember: roomService.getSelf(),
            roomExpress: roomExpress,
            renderer: userMedia?.renderer,
            audioTracks: userMedia?.audioTracks,
            queue: queue
        )

        self.members = []
    }

    public func subscribeToMemberList() {
        queue.async { [weak self] in
            guard let self = self else { return }
            os_log(
                .debug,
                log: .memberController,
                "%{private}s, Subscribe to room member list updates",
                self.roomDescription
            )
            self.memberListDisposable = self.roomService?
                .getObservableActiveRoom()
                .getValue()
                .getObservableMembers()
                .subscribe(self.memberListDidChange)
        }
    }

    public func recentlyLoudestMember() -> RoomMember? {
        members
            .filter { $0.state == .active && $0.media.isAudioAvailable == true }
            .max { $0.media.recentAudioLevel() < $1.media.recentAudioLevel() }
    }
}

// MARK: - Internal methods
internal extension RoomMemberController {
    func dispose() {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(.debug, log: .memberController, "%{private}s, Dispose", roomDescription)

        self.memberListDisposable = nil
        self.members.forEach { $0.dispose() }
        self.members.removeAll()
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
        // Also update the current member list.
        process(
            newMembers: newMembers,
            oldMembers: self.members,
            connectedMemberHandler: membersConnected,
            disconnectedMemberHandler: membersDisconnected
        )
    }

    /// Find out, did the members list has changes inside it
    ///
    /// Searches the members list for newly connected members and for disconnected members.
    /// - Parameters:
    ///   - newMembers: Received member list
    ///   - oldMembers: Current member list
    ///   - connectedMemberHandler: Closure for handling members, if there are any who just now connected.
    ///   - disconnectedMemberHandler: Closure for handling members, if there are any who just now disconnected.
    func process(newMembers: Set<RoomMember>, oldMembers: Set<RoomMember>, connectedMemberHandler: (Set<RoomMember>) -> Void, disconnectedMemberHandler: (Set<RoomMember>) -> Void) {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(
            .debug,
            log: .memberController,
            "%{private}s, Old members: %{private}s",
            roomDescription,
            oldMembers.description
        )

        os_log(
            .debug,
            log: .memberController,
            "%{private}s, New members: %{PRIVATE}s",
            roomDescription,
            newMembers.description
        )

        // Get list of elements which does not exist in updatedMemberList but exist in currentMemberList, in simple words, members who left.
        let disconnectedMembers = oldMembers.subtracting(newMembers)
        disconnectedMemberHandler(disconnectedMembers)

        // Get list of elements which does no.
        let connectedMembers = newMembers.subtracting(oldMembers)
        connectedMemberHandler(connectedMembers)
    }

    func membersConnected(_ newMembers: Set<RoomMember>) {
        dispatchPrecondition(condition: .onQueue(queue))

        guard newMembers.isEmpty == false else { return }

        members.formUnion(newMembers)
        os_log(
            .debug,
            log: .memberController,
            "%{private}s, Members connected to the room: %{private}s",
            roomDescription,
            newMembers.description
        )

        for member in newMembers {
            // Observe new member streams
            member.addStateObserver(self)
            member.observeStreams()
        }
    }

    func membersDisconnected(_ oldMembers: Set<RoomMember>) {
        dispatchPrecondition(condition: .onQueue(queue))

        guard oldMembers.isEmpty == false else { return }

        os_log(
            .debug,
            log: .memberController,
            "%{private}s, Members disconnected from the room: %{private}s",
            roomDescription,
            oldMembers.description
        )
        members.subtract(oldMembers)

        for member in oldMembers {
            member.dispose()
        }
    }

    func membersListDidChange(_ members: Set<RoomMember>) {
        dispatchPrecondition(condition: .onQueue(queue))

        let sortedMembers = members.sorted()
        delegate?.memberListDidChange(sortedMembers)
    }

    func makeRoomMember(_ member: PhenixMember) -> RoomMember {
        dispatchPrecondition(condition: .onQueue(queue))

        guard let roomExpress = roomExpress else {
            fatalError("Room Express must be provided")
        }

        guard member != currentMember else {
            return currentMember
        }

        let newMember = RoomMember(remoteMember: member, roomExpress: roomExpress, queue: queue)
        newMember.membersControllerDelegate = self

        return newMember
    }
}

// MARK: - RoomMemberControllerDelegate
extension RoomMemberController: RoomMemberControllerDelegate {
    /// Checks if the limit of the member subscription with video is reached.
    /// - Returns: Bool, `true` - can subscribe with video, `false` - limit is reached, should not subscribe with video
    func canSubscribeForVideo() -> Bool {
//        dispatchPrecondition(condition: .onQueue(queue))

        // Calculate, how many of members have video subscription at the moment.
        let videoSubscriptions = members.reduce(into: 0) { result, member in
            result += member.subscribesToVideo ? 1 : 0
        }

        os_log(
            .debug,
            log: .memberController,
            "%{private}s, Active video subscriptions: %{private}s/%{private}s",
            roomDescription,
            videoSubscriptions.description,
            maxVideoSubscriptions.description
        )

        if videoSubscriptions + 1 <= maxVideoSubscriptions {
            return true
        } else {
            return false
        }
    }
}

// MARK: - RoomMemberStateObserver
extension RoomMemberController: RoomMemberStateObserver {
    public func roomMember(_ member: RoomMember, didChange state: RoomMember.State) {
        membersListDidChange(members)
    }
}

// MARK: - Observable callback methods
private extension RoomMemberController {
    func memberListDidChange(_ changes: PhenixObservableChange<NSArray>?) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }

            guard let members = changes?.value as? [PhenixMember] else {
                return
            }

            os_log(
                .debug,
                log: .memberController,
                "%{private}s, Member list did change",
                self.roomDescription
            )

            self.processLatestMembers(members)
        }
    }
}

// MARK: - Sequence where Element == RoomMember
fileprivate extension Sequence where Element == RoomMember {
    /// Sort `RoomMember` list in a way that the `Self` member always will be first, then the second member always will be the one who joined last
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
