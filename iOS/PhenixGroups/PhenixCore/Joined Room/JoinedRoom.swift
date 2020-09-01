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

    init(roomExpress: PhenixRoomExpress, backend: URL, roomService: PhenixRoomService, chatService: PhenixRoomChatService, publisher: PhenixExpressPublisher? = nil) {
        self.roomExpress = roomExpress
        self.backend = backend
        self.publisher = publisher
        self.roomService = roomService
        self.chatService = chatService

        self.currentMember = RoomMember(roomService.getSelf(), isSelf: true, roomExpress: roomExpress)
    }

    internal func dispose() {
        os_log(.debug, log: .joinedRoom, "Dispose joined room %{PRIVATE}s", self.description)
        disposables.removeAll() // Disposables must be cleared so that they could not cause a memory leak.
        membersDelegate = nil
        chatDelegate = nil
        membersLeft(members)
    }

    public func leave() {
        dispose()
        publisher?.stop()
        os_log(.debug, log: .joinedRoom, "Leave joined room %{PRIVATE}s", self.description)
        roomService.leaveRoom { [weak self] _, _ in
            guard let self = self else { return }
            self.delegate?.roomLeft(self)
            os_log(.debug, log: .joinedRoom, "Left joined room %{PRIVATE}s", self.description)
        }
    }

    public func setAudio(enabled: Bool) {
        os_log(.debug, log: .joinedRoom, "Set user media publisher audio enabled - %{PUBLIC}d", enabled)

        if enabled {
            publisher?.enableAudio()
        } else {
            publisher?.disableAudio()
        }
    }

    public func setVideo(enabled: Bool) {
        os_log(.debug, log: .joinedRoom, "Set user media publisher video enabled - %{PUBLIC}d", enabled)

        if enabled {
            publisher?.enableVideo()
        } else {
            publisher?.disableVideo()
        }
    }

    public func send(message: String) {
        chatService.sendMessage(toRoom: message)
    }

    public func subscribeToMemberList(_ delegate: JoinedRoomMembersDelegate) {
        os_log(.debug, log: .joinedRoom, "Subscribe to room member list updates")
        membersDelegate = delegate
        roomService.getObservableActiveRoom()?.getValue()?.getObservableMembers()?.subscribe(memberListDidChange)?.append(to: &disposables)
    }

    public func subscribeToChatMessages(_ delegate: JoinedRoomChatDelegate) {
        os_log(.debug, log: .joinedRoom, "Subscribe to room chat message updates")
        chatDelegate = delegate
        chatService.getObservableChatMessages()?.subscribe(chatMessagesDidChange)?.append(to: &disposables)
    }
}

private extension JoinedRoom {
    func memberListDidChange(_ changes: PhenixObservableChange<NSArray>?) {
        guard let updatedList = changes?.value as? [PhenixMember] else {
            return
        }

        let updatedMemberList = Set(updatedList.map { makeRoomMember($0) })

        let memberListChanged = processUpdatedMemberList(updatedMemberList, currentMemberList: members, membersJoined: membersJoined, membersLeft: membersLeft)

        if memberListChanged {
            let memberList = Array(members).sorted { lhs, rhs -> Bool in
                if lhs.isSelf {
                    return true
                } else if rhs.isSelf {
                    return false
                }

                return lhs > rhs
            }
            membersDelegate?.memberListDidChange(memberList)
        }
    }

    func processUpdatedMemberList(_ updatedMemberList: Set<RoomMember>, currentMemberList: Set<RoomMember>, membersJoined: (Set<RoomMember>) -> Void, membersLeft: (Set<RoomMember>) -> Void) -> Bool {
        // Get list of elements which does not exist in updatedMemberList but exist in currentMemberList, in simple words, members who left
        let leftMembers = currentMemberList.subtracting(updatedMemberList)
        membersLeft(leftMembers)

        // Get list of elements which does not exist in currentMemberList but exist in updatedMemberList, in simple words, members who joined recently
        let joinedMembers = updatedMemberList.subtracting(currentMemberList)
        membersJoined(joinedMembers)

        return leftMembers.isEmpty == false || joinedMembers.isEmpty == false
    }

    func membersJoined(_ newMembers: Set<RoomMember>) {
        guard newMembers.isEmpty == false else {
            return
        }

        members.formUnion(newMembers)
        os_log(.debug, log: .joinedRoom, "Members joined to the room: %{PRIVATE}s", newMembers.description)

        for member in newMembers {
            // Observe new member stream and then automatically subscribe to it
            member.delegate = self
            member.observeStream()
        }
    }

    func membersLeft(_ oldMembers: Set<RoomMember>) {
        guard oldMembers.isEmpty == false else { return }
        members.subtract(oldMembers)
        os_log(.debug, log: .joinedRoom, "Members left from the room: %{PRIVATE}s", oldMembers.description)
        oldMembers.forEach { $0.dispose() }
    }

    func makeRoomMember(_ member: PhenixMember) -> RoomMember {
        guard let roomExpress = roomExpress else {
            fatalError("Room Express must be provided")
        }

        if let currentMember = currentMember, member == currentMember {
            return currentMember
        } else {
            return RoomMember(member, isSelf: false, roomExpress: roomExpress)
        }
    }

    func chatMessagesDidChange(_ changes: PhenixObservableChange<NSArray>?) {
        guard let chatMessages = changes?.value as? [PhenixChatMessage] else {
            return
        }

        var messages = chatMessages.compactMap(RoomChatMessage.init)

        for (index, message) in messages.enumerated() where message.authorName == currentMember.screenName {
            messages[index].maskAsYourself()
        }

        chatDelegate?.chatMessagesDidChange(messages)
    }

    func subscribe(_ member: RoomMember, to streams: [PhenixStream]) {
        dispatchPrecondition(condition: .notOnQueue(.main))

        let subscriptionType: RoomMember.SubscriptionType
        if canMemberSubscribeWithVideo(members: members) {
            subscriptionType = .video
        } else {
            subscriptionType = .audio
        }

        let group = DispatchGroup()

        for stream in streams {
            os_log(.debug, log: .joinedRoom, "Subscribe to member stream: %{PRIVATE}s with %{PRIVATE}s, (%{PRIVATE}s)", stream.description, String(describing: subscriptionType), member.description)

            group.enter()
            var subscribed = false
            member.subscribe(to: stream, with: subscriptionType) { succeeded in
                subscribed = succeeded
                group.leave()
            }
            group.wait()

            if subscribed {
                os_log(.debug, log: .joinedRoom, "Successfully subscribed to member stream: %{PRIVATE}s, (%{PRIVATE}s)", stream.description, member.description)
                break
            } else {
                os_log(.debug, log: .joinedRoom, "Failed to subscribe to member stream: %{PRIVATE}s, retrying with next stream if possible, (%{PRIVATE}s)", stream.description, member.description)
            }
        }
    }

    func canMemberSubscribeWithVideo(members: Set<RoomMember>) -> Bool {
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
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.subscribe(member, to: streams)
        }
    }
}
