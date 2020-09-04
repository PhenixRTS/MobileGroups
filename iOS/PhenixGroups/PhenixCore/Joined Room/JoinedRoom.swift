//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

public class JoinedRoom: CustomStringConvertible {
    enum JoinedRoomError: Error {
        case noRoomExpress
    }

    private static let maxVideoSubscriptions = 3

    private weak var roomExpress: PhenixRoomExpress?
    private weak var membersDelegate: JoinedRoomMembersDelegate?
    private weak var chatDelegate: JoinedRoomChatDelegate?

    private let queue: DispatchQueue
    private let roomService: PhenixRoomService
    private let chatService: PhenixRoomChatService
    private let publisher: PhenixExpressPublisher?
    private var disposables = [PhenixDisposable]()

    internal weak var delegate: JoinedRoomDelegate?

    public private(set) var currentMember: RoomMember!
    public private(set) var members = Set<RoomMember>()
    public let backend: URL
    public var alias: String? {
        roomService.getObservableActiveRoom()?.getValue()?.getObservableAlias()?.getValue() as String?
    }

    public var description: String {
        "Joined Room, backend: \(backend.absoluteURL), alias: \(String(describing: alias))"
    }

    init(roomExpress: PhenixRoomExpress, backend: URL, roomService: PhenixRoomService, chatService: PhenixRoomChatService, queue: DispatchQueue, publisher: PhenixExpressPublisher? = nil) {
        self.roomExpress = roomExpress
        self.backend = backend
        self.publisher = publisher
        self.roomService = roomService
        self.chatService = chatService
        self.queue = queue

        self.currentMember = RoomMember(roomService.getSelf(), isSelf: true, roomExpress: roomExpress, rootQueue: queue)
    }

    /// Clears all room disposables and all member subscriptions
    ///
    /// Must be called when SDK automatically re-publishes to the room, also if user didn't left the room manually.
    internal func destroy() {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }

            os_log(.debug, log: .joinedRoom, "Destroy the joined room members, (%{PRIVATE}s)", self.description)

            self.disposables.removeAll()
            self.members.forEach { $0.dispose() }
        }
    }

    /// Clears all room disposables and all member subscriptions, stops publishing and leaves the room with SDK method
    public func leave() {
        queue.sync { [weak self] in
            guard let self = self else {
                return
            }

            os_log(.debug, log: .joinedRoom, "Dispose joined room members, (%{PRIVATE}s)", self.description)

            self.disposables.removeAll()
            self.members.forEach { $0.dispose() }

            self.publisher?.stop()

            os_log(.debug, log: .joinedRoom, "Leave joined room, (%{PRIVATE}s)", self.description)
            self.roomService.leaveRoom { _, _ in
                self.delegate?.roomLeft(self)
                os_log(.debug, log: .joinedRoom, "Joined room left, (%{PRIVATE}s)", self.description)
            }
        }
    }

    public func setAudio(enabled: Bool) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }

            os_log(.debug, log: .joinedRoom, "Set user media publisher audio enabled - %{PUBLIC}d", enabled)

            if enabled {
                self.publisher?.enableAudio()
            } else {
                self.publisher?.disableAudio()
            }
        }
    }

    public func setVideo(enabled: Bool) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }

            os_log(.debug, log: .joinedRoom, "Set user media publisher video enabled - %{PUBLIC}d", enabled)

            if enabled {
                self.publisher?.enableVideo()
            } else {
                self.publisher?.disableVideo()
            }
        }
    }

    public func send(message: String) {
        queue.async { [weak self] in
            self?.chatService.sendMessage(toRoom: message)
        }
    }

    public func subscribeToMemberList(_ delegate: JoinedRoomMembersDelegate) {
        queue.async { [weak self] in
            guard let self = self else { return }
            os_log(.debug, log: .joinedRoom, "Subscribe to room member list updates")
            self.membersDelegate = delegate
            self.roomService.getObservableActiveRoom()?.getValue()?.getObservableMembers()?.subscribe(self.memberListDidChange)?.append(to: &self.disposables)
        }
    }

    public func subscribeToChatMessages(_ delegate: JoinedRoomChatDelegate) {
        queue.async { [weak self] in
            guard let self = self else { return }
            os_log(.debug, log: .joinedRoom, "Subscribe to room chat message updates")
            self.chatDelegate = delegate
            self.chatService.getObservableChatMessages()?.subscribe(self.chatMessagesDidChange)?.append(to: &self.disposables)
        }
    }
}

private extension JoinedRoom {
    func memberListDidChange(_ changes: PhenixObservableChange<NSArray>?) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }

            guard let updatedList = changes?.value as? [PhenixMember] else {
                return
            }

            let updatedMemberList = Set(updatedList.map { self.makeRoomMember($0) })

            let memberListChanged = self.processUpdatedMemberList(updatedMemberList, currentMemberList: self.members, membersJoined: self.membersJoined, membersLeft: self.membersLeft)

            if memberListChanged {
                let memberList = Array(self.members).sorted { lhs, rhs -> Bool in
                    if lhs.isSelf {
                        return true
                    } else if rhs.isSelf {
                        return false
                    }

                    return lhs > rhs
                }
                self.membersDelegate?.memberListDidChange(memberList)
            }
        }
    }

    func processUpdatedMemberList(_ updatedMemberList: Set<RoomMember>, currentMemberList: Set<RoomMember>, membersJoined: (Set<RoomMember>) -> Void, membersLeft: (Set<RoomMember>) -> Void) -> Bool {
        dispatchPrecondition(condition: .onQueue(queue))
        // Get list of elements which does not exist in updatedMemberList but exist in currentMemberList, in simple words, members who left
        let leftMembers = currentMemberList.subtracting(updatedMemberList)
        membersLeft(leftMembers)

        // Get list of elements which does not exist in currentMemberList but exist in updatedMemberList, in simple words, members who joined recently
        let joinedMembers = updatedMemberList.subtracting(currentMemberList)
        membersJoined(joinedMembers)

        return leftMembers.isEmpty == false || joinedMembers.isEmpty == false
    }

    func membersJoined(_ newMembers: Set<RoomMember>) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard newMembers.isEmpty == false else {
            return
        }

        members.formUnion(newMembers)
        os_log(.debug, log: .joinedRoom, "Members joined to the room: %{PRIVATE}s", newMembers.description)

        for member in newMembers {
            // Observe new member stream and then automatically subscribe to it
            member.delegate = self
            member.observeStreams()
        }
    }

    func membersLeft(_ oldMembers: Set<RoomMember>) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard oldMembers.isEmpty == false else { return }
        members.subtract(oldMembers)
        os_log(.debug, log: .joinedRoom, "Members left from the room: %{PRIVATE}s", oldMembers.description)
        oldMembers.forEach { $0.dispose() }
    }

    func makeRoomMember(_ member: PhenixMember) -> RoomMember {
        dispatchPrecondition(condition: .onQueue(queue))
        guard let roomExpress = roomExpress else {
            fatalError("Room Express must be provided")
        }

        if let currentMember = currentMember, member == currentMember {
            return currentMember
        } else {
            return RoomMember(member, isSelf: false, roomExpress: roomExpress, rootQueue: queue)
        }
    }

    func chatMessagesDidChange(_ changes: PhenixObservableChange<NSArray>?) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }

            guard let chatMessages = changes?.value as? [PhenixChatMessage] else {
                return
            }

            var messages = chatMessages.compactMap(RoomChatMessage.init)

            for (index, message) in messages.enumerated() where message.authorName == self.currentMember.screenName {
                messages[index].maskAsYourself()
            }

            self.chatDelegate?.chatMessagesDidChange(messages)
        }
    }

    func subscribe(_ member: RoomMember, to streams: [PhenixStream]) {
        dispatchPrecondition(condition: .onQueue(queue))

        let subscriptionType: RoomMember.SubscriptionType
        if canMemberSubscribeWithVideo(members: members) {
            subscriptionType = .video
        } else {
            subscriptionType = .audio
        }

        subscribe(member, to: streams, with: subscriptionType)
    }

    private func subscribe(_ member: RoomMember, to streams: [PhenixStream], with type: RoomMember.SubscriptionType) {
        dispatchPrecondition(condition: .onQueue(queue))

        guard streams.isEmpty == false else {
            return
        }

        var streams = streams
        let stream = streams.removeFirst()

        os_log(.debug, log: .joinedRoom, "Subscribe to member stream: %{PRIVATE}s with %{PRIVATE}s, (%{PRIVATE}s)", stream.description, String(describing: type), member.description)

        member.subscribe(to: stream, with: type) { [weak self] succeeded in
            self?.queue.async {
                if succeeded {
                    os_log(.debug, log: .joinedRoom, "Successfully subscribed to member stream: %{PRIVATE}s, (%{PRIVATE}s)", stream.description, member.description)
                } else {
                    os_log(.debug, log: .joinedRoom, "Failed to subscribe to member stream: %{PRIVATE}s, retrying with next stream if possible, (%{PRIVATE}s)", stream.description, member.description)
                    self?.subscribe(member, to: streams, with: type)
                }
            }
        }
    }

    func canMemberSubscribeWithVideo(members: Set<RoomMember>) -> Bool {
        dispatchPrecondition(condition: .onQueue(queue))
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

// MARK: - Hashable
extension JoinedRoom: Hashable {
    public static func == (lhs: JoinedRoom, rhs: JoinedRoom) -> Bool {
        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// MARK: - RoomMemberDelegate
extension JoinedRoom: RoomMemberDelegate {
    func memberStreamDidChange(_ member: RoomMember, streams: [PhenixStream]) {
        queue.async { [weak self] in
            self?.subscribe(member, to: streams)
        }
    }
}
