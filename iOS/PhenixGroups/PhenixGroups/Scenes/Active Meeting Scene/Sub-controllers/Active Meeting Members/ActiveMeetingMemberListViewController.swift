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

        // Crete a copy of previously selected row
        let pinnedIndexPath = dataSource.indexPathForSelectedRow

        // Check if previously selected row exists (case when user first time selects a row, there will not be previously selected row)
        if let oldIndexPath = pinnedIndexPath {
            unpin(cellAt: oldIndexPath)
        }

        // Check if currently selected row is not the same as previously selected row
        if indexPath != pinnedIndexPath {
            pin(cellAt: indexPath)

            // Set focus (move member's previewLayer from the cell to the main preview at the top of the view)
            let member = dataSource.members[indexPath.row]
            delegate?.setFocus(on: member)
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ActiveMeetingMemberTableViewCell else {
            return
        }

        let member = dataSource.members[indexPath.row]

        guard member != delegate?.focusedMember else {
            return
        }

        cell.configureVideo()
    }

    /// Reconfigures member previewLayer to be shown inside the member's cell.
    /// - Parameter member: Specific member, which previewLayer must be set to be visible inside the cell
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
        case noPinnedMember
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

    func pin(cellAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ActiveMeetingMemberTableViewCell {
            cell.pin()
        }
        dataSource.pinnedMember = dataSource.members[indexPath.row]
        dataSource.indexPathForSelectedRow = indexPath
    }

    func unpin(cellAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ActiveMeetingMemberTableViewCell {
            cell.unpin()
        }
        dataSource.pinnedMember = nil
        dataSource.indexPathForSelectedRow = nil
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
                self.unpin(cellAt: oldIndexPath)
                self.tableView.reloadData()
                self.pin(cellAt: newIndexPath)

            case .memberRemoved(let oldIndexPath):
                self.unpin(cellAt: oldIndexPath)
                self.tableView.reloadData()
                // Members are ordered by their activity timestamp, and also first member always is current device user
                let member = self.dataSource.members.count > 1 ? self.dataSource.members[1] : self.dataSource.members[0]
                self.delegate?.setFocus(on: member)

            case .memberNotMoved,
                 .noPinnedMember:
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

        // Check if a member has been pinned
        guard let pinnedMember = dataSource.pinnedMember, let previousPinnedMemberIndex = dataSource.indexPathForSelectedRow?.row else {
            reloadMemberList(position: .noPinnedMember)
            return
        }

        // Check if pinned member still exists in the member list
        guard let currentPinnedMemberIndex = list.firstIndex(where: { $0 == pinnedMember }) else {
            reloadMemberList(position: .memberRemoved(oldIndexPath: IndexPath(row: previousPinnedMemberIndex, section: 0)))
            return
        }

        // Check if pinned member row index has changed after the member list update
        if currentPinnedMemberIndex != previousPinnedMemberIndex {
            reloadMemberList(position: .memberRelocated(oldIndexPath: .for(rowIndex: previousPinnedMemberIndex), newIndexPath: .for(rowIndex: currentPinnedMemberIndex)))
        } else {
            reloadMemberList(position: .memberNotMoved)
        }
    }
}

fileprivate extension IndexPath {
    static func `for`(rowIndex index: Int) -> IndexPath {
        IndexPath(row: index, section: 0)
    }
}
