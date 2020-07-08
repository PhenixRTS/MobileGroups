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

    init(roomExpress: PhenixRoomExpress, backend: URL, roomService: PhenixRoomService, publisher: PhenixExpressPublisher? = nil) {
        self.roomExpress = roomExpress
        self.backend = backend
        self.publisher = publisher
        self.roomService = roomService
        self.chatService = PhenixRoomChatServiceFactory.createRoomChatService(roomService)
      
        self.currentMember = RoomMember(roomService.getSelf(), isSelf: true, roomExpress: roomExpress)
    }

    public func leave() {
        os_log(.debug, log: .joinedRoom, "Leaving joined room %{PRIVATE}s", self.description)
        publisher?.stop()
        disposables.removeAll() // Disposables must be cleared so that they could not cause a memory leak.
        currentMember = nil
        membersLeft(members)
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

    public func send(message: String) {
        chatService.sendMessage(toRoom: message)
    }

    public func subscribeToMemberList(_ delegate: JoinedRoomMembersDelegate) {
        os_log(.debug, log: .joinedRoom, "Subscribe to member list updates")
        membersDelegate = delegate
        if let members = roomService.getObservableActiveRoom()?.getValue()?.getObservableMembers() {
            members.subscribe(memberListDidChange)?.append(to: &disposables)
            os_log(.debug, log: .joinedRoom, "Successfully subscribed to member list updates")
        }
    }

    public func subscribeToChatMessages(_ delegate: JoinedRoomChatDelegate) {
        os_log(.debug, log: .joinedRoom, "Subscribe to chat messages")
        chatDelegate = delegate
        chatService.getObservableChatMessages()?.subscribe(chatMessagesDidChange)?.append(to: &disposables)
    }
}

private extension JoinedRoom {
    func memberListDidChange(_ changes: PhenixObservableChange<NSArray>?) {
        guard let updatedList = changes?.value as? [PhenixMember] else {
            return
        }

        let updatedMemberList = Set(updatedList.compactMap { try? makeRoomMember($0) })

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
        guard newMembers.isEmpty == false else { return }
        os_log(.debug, log: .joinedRoom, "Members joined: %{PRIVATE}s", newMembers.description)
        members.formUnion(newMembers)
        newMembers.forEach { $0.observe() }
    }

    func membersLeft(_ oldMembers: Set<RoomMember>) {
        guard oldMembers.isEmpty == false else { return }
        os_log(.debug, log: .joinedRoom, "Members left: %{PRIVATE}s", oldMembers.description)
        members.subtract(oldMembers)
        oldMembers.forEach { $0.dispose() }
    }

    func makeRoomMember(_ member: PhenixMember) throws -> RoomMember {
        guard let roomExpress = roomExpress else {
            throw JoinedRoomError.noRoomExpress
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

        for (index, message) in messages.enumerated() where message.authorId == currentMember.identifier {
            messages[index].maskAsYourself()
        }

        chatDelegate?.chatMessagesDidChange(messages)
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
