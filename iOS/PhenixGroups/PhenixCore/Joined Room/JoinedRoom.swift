//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

public class JoinedRoom: CustomStringConvertible {
    private let roomService: PhenixRoomService
    private let publisher: PhenixExpressPublisher?

    private var disposables = [PhenixDisposable]()
    private var memberList = [PhenixMember]()

    private weak var membersDelegate: JoinedRoomMembersDelegate?

    public let backend: URL
    public var alias: String? {
        roomService.getObservableActiveRoom()?.getValue()?.getObservableAlias()?.getValue() as String?
    }

    weak var delegate: JoinedRoomDelegate?

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
        disposables.removeAll() // Disposables must be cleared so that they could not cause a memory leak.
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

    public func subscribeToMemberList(_ delegate: JoinedRoomMembersDelegate) {
        os_log(.debug, log: .joinedRoom, "Subscribe to member list updates")
        membersDelegate = delegate
        if let members = roomService.getObservableActiveRoom()?.getValue()?.getObservableMembers() {
            disposables.append(members.subscribe(memberListDidChange))
            os_log(.debug, log: .joinedRoom, "Subscribe to member list updates")
        }
    }
}

private extension JoinedRoom {
    func memberListDidChange(_ changes: PhenixObservableChange<NSArray>?) {
        guard let newMemberList = changes?.value as? [PhenixMember] else {
            return
        }

        // Logic for members list

        if newMemberList.count != memberList.count {
            memberList = newMemberList
            membersDelegate?.memberListDidChange(newMemberList.compactMap { $0.getObservableScreenName()?.getValue() as String? })
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
