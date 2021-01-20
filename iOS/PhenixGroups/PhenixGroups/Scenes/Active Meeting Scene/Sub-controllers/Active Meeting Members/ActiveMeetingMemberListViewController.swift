//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

class ActiveMeetingMemberListViewController: UITableViewController, PageContainerMember {
    lazy var dataSource = ActiveMeetingMemberListDataSource()
    lazy var pageIcon = UIImage(named: "meeting_members_icon")

    weak var delegate: ActiveMeetingPreview?

    var pinnedMemberExist: Bool {
        dataSource.pinnedMember != nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }

        os_log(.debug, log: .activeMeetingScene, "Member row selected (%{PRIVATE}s)", indexPath.description)

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

    func resetPinnedMember() {
        dataSource.pinnedMember = nil
        dataSource.indexPathForSelectedRow = nil
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
        resetPinnedMember()
    }

    /// Sets focused member for the main view video preview layer
    func setDefaultFocusedMemberIfPossible() {
        guard pinnedMemberExist == false else {
            os_log(.debug, log: .activeMeetingScene, "Pinned member already exist, focus isn't changed.")
            return
        }

        let memberCount = dataSource.members.count

        guard memberCount > 0 else {
            os_log(.error, log: .activeMeetingScene, "No members available for the currently joined meeting.")
            delegate?.setFocus(on: nil)
            return
        }

        // Members are ordered by their activity timestamp.
        // Notes:
        // 1. first member always is the current device user
        // 2. second member has the latest activity timestamp (ordered by newest timestamp first )
        let member = memberCount > 1 ? dataSource.members[1] : dataSource.members[0]
        delegate?.setFocus(on: member)
    }

    /// Reloads tableview with additional logic for pinned member cell
    ///
    /// If user has a pinned member, it will make necessary updates to save new pinned row location or remove it if necessary.
    /// - Parameter pinnedMemberPosition: Pinned member position type
    func reloadMemberList(pinnedMemberPosition: PinnedMemberPosition) {
        switch pinnedMemberPosition {
        case .memberRelocated(let oldIndexPath, let newIndexPath):
            unpin(cellAt: oldIndexPath)
            tableView.reloadData()
            pin(cellAt: newIndexPath)

        case .memberRemoved(let oldIndexPath):
            unpin(cellAt: oldIndexPath)
            tableView.reloadData()
            setDefaultFocusedMemberIfPossible()

        case .memberNotMoved,
             .noPinnedMember:
            tableView.reloadData()
            setDefaultFocusedMemberIfPossible()
        }
    }
}

// MARK: - JoinedRoomMembersDelegate
extension ActiveMeetingMemberListViewController: JoinedRoomMembersDelegate {
    func memberListDidChange(_ list: [RoomMember]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            os_log(.debug, log: .activeMeetingScene, "Member list did change, %{PRIVATE}s", list.description)

            self.dataSource.members = list
            self.title = "(\(list.count))"

            // Update currently pinned member in the list

            // Check if a member has been pinned
            guard let pinnedMember = self.dataSource.pinnedMember, let previousPinnedMemberIndex = self.dataSource.indexPathForSelectedRow?.row else {
                self.reloadMemberList(pinnedMemberPosition: .noPinnedMember)
                return
            }

            // Check if pinned member still exists in the member list
            guard let currentPinnedMemberIndex = list.firstIndex(where: { $0 == pinnedMember }) else {
                self.reloadMemberList(pinnedMemberPosition: .memberRemoved(oldIndexPath: IndexPath(row: previousPinnedMemberIndex, section: 0)))
                return
            }

            // Check if pinned member row index has changed after the member list update
            if currentPinnedMemberIndex != previousPinnedMemberIndex {
                self.reloadMemberList(pinnedMemberPosition: .memberRelocated(oldIndexPath: .for(rowIndex: previousPinnedMemberIndex), newIndexPath: .for(rowIndex: currentPinnedMemberIndex)))
            } else {
                self.reloadMemberList(pinnedMemberPosition: .memberNotMoved)
            }
        }
    }
}

// MARK: - Helper methods
fileprivate extension IndexPath {
    static func `for`(rowIndex index: Int) -> IndexPath {
        IndexPath(row: index, section: 0)
    }
}
