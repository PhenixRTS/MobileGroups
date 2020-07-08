//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

class ActiveMeetingMemberListViewController: UITableViewController, PageContainerMember {
    private static let maxVideoSubscriptions = 3
    lazy var dataSource = ActiveMeetingMemberListDataSource()
    lazy var pageIcon = UIImage(named: "meeting_members_icon")

    weak var delegate: ActiveMeetingPreview?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        let pinnedIndexPath = dataSource.indexPathForSelectedRow

        if let oldIndexPath = pinnedIndexPath {
            unpinCell(at: oldIndexPath)
        }

        if indexPath != pinnedIndexPath { // No previously pinned row or new pinned row selected
            pinCell(at: indexPath)

            let member = dataSource.members[indexPath.row]
            delegate?.setFocus(on: member)
        }
    }

    func reloadVideoPreview(for member: RoomMember) {
        if let indexPath = dataSource.indexPath(of: member) {
            if let cell = tableView.cellForRow(at: indexPath) as? ActiveMeetingMemberTableViewCell {
                cell.configureVideo()
            }
        }
    }
}

private extension ActiveMeetingMemberListViewController {
    enum PinnedMemberPosition {
        case memberRemoved(oldIndexPath: IndexPath)
        case memberRelocated(oldIndexPath: IndexPath, newIndexPath: IndexPath)
        case memberNotMoved
        case noSelectedMember
    }

    func configureTableView() {
        tableView.dataSource = dataSource
        tableView.register(ActiveMeetingMemberTableViewCell.self, forCellReuseIdentifier: ActiveMeetingMemberTableViewCell.identifier)
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delaysContentTouches = false
        tableView.allowsSelection = true
        tableView.tableFooterView = UIView()

        dataSource.retrieveFocusedMember = { [weak self] in
            self?.delegate?.focusedMember
        }
    }

    func unpinCell(at indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ActiveMeetingMemberTableViewCell {
            dataSource.unpin(cell, at: indexPath)
        }
        dataSource.indexPathForSelectedRow = nil
    }

    func pinCell(at indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ActiveMeetingMemberTableViewCell {
            dataSource.pin(cell, at: indexPath)
        }
        dataSource.indexPathForSelectedRow = indexPath
    }

    func subscribe(to list: [RoomMember]) {
        // Calculate how many of members have video subscriptions at the moment.
        var videoSubscriptions = list.reduce(into: 0) { result, member in
            result += member.subscriptionType == .some(.video) ? 1 : 0
        }

        // Subscribe to members
        list.forEach { member in
            if member.isSubscribed == false {
                if member.isSelf == false && videoSubscriptions + 1 <= Self.maxVideoSubscriptions {
                    videoSubscriptions += 1
                    member.subscribe(for: .video)
                } else {
                    member.subscribe(for: .audio)
                }
            }
        }
    }

    private func reloadMemberList(position: PinnedMemberPosition) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            switch position {
            case .memberRelocated(let oldIndexPath, let newIndexPath):
                self.unpinCell(at: oldIndexPath)
                self.tableView.reloadData()
                self.pinCell(at: newIndexPath)

            case .memberRemoved(let oldIndexPath):
                self.unpinCell(at: oldIndexPath)
                self.tableView.reloadData()
                // Members are ordered by their activity timestamp, and also first member always is current device user
                let member = self.dataSource.members.count > 1 ? self.dataSource.members[1] : self.dataSource.members[0]
                self.delegate?.setFocus(on: member)

            case .memberNotMoved,
                 .noSelectedMember:
                self.tableView.reloadData()
                // Members are ordered by their activity timestamp, and also first member always is current device user
                let member = self.dataSource.members.count > 1 ? self.dataSource.members[1] : self.dataSource.members[0]
                self.delegate?.setFocus(on: member)
            }
        }
    }
}

// - MARK: JoinedRoomMembersDelegate
extension ActiveMeetingMemberListViewController: JoinedRoomMembersDelegate {
    func memberListDidChange(_ list: [RoomMember]) {
        dataSource.members = list
        title = "(\(list.count))"

        subscribe(to: list)

        // Update currently pinned member in the list

        guard let pinnedMember = dataSource.pinnedMember, let previousPinnedMemberIndex = self.dataSource.indexPathForSelectedRow?.row else {
            reloadMemberList(position: .noSelectedMember)
            return
        }

        guard let currentPinnedMemberIndex = list.firstIndex(where: { $0 == pinnedMember }) else {
            reloadMemberList(position: .memberRemoved(oldIndexPath: IndexPath(row: previousPinnedMemberIndex, section: 0)))
            return
        }

        // Selected member still exists in the room
        if currentPinnedMemberIndex != previousPinnedMemberIndex {
            reloadMemberList(position: .memberRelocated(oldIndexPath: IndexPath(row: previousPinnedMemberIndex, section: 0), newIndexPath: IndexPath(row: currentPinnedMemberIndex, section: 0)))
        } else {
            reloadMemberList(position: .memberNotMoved)
        }
    }
}
