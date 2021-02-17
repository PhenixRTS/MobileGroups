//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

protocol MemberFocusDelegate: AnyObject {
    func memberObtainedFocus(_ member: RoomMember)
    func memberLostFocus(_ member: RoomMember)
}

class ActiveMeetingMemberListViewController: UITableViewController, PageContainerMember {
    lazy var dataSource = ActiveMeetingMemberListDataSource()
    lazy var pageIcon = UIImage(named: "meeting_members_icon")

    weak var delegate: ActiveMeetingPreview?

    var pinnedMemberExist: Bool {
        tableView.indexPathForSelectedRow != nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath == tableView.indexPathForSelectedRow {
            // Trying to select the same cell which is already selected - deselect this cell.
            tableView.deselectRow(at: indexPath, animated: false)
            deselect(indexPath)
            return nil
        }

        return indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        select(indexPath)
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        deselect(indexPath)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ActiveMeetingMemberTableViewCell else { return }

        let member = dataSource.members[indexPath.row]

        guard member != delegate?.focusedMember else { return }

        cell.configureVideo()
    }

    func select(_ indexPath: IndexPath) {
        os_log(.debug, log: .activeMeetingScene, "Member row selected (%{PRIVATE}s)", indexPath.description)

        pin(cellAt: indexPath)

        // Set focus (move member's previewLayer from the cell to the main preview at the top of the view)
        let member = dataSource.members[indexPath.row]
        delegate?.setFocus(on: member)
    }

    func deselect(_ indexPath: IndexPath) {
        unpin(cellAt: indexPath)
    }
}

// MARK: Private methods
private extension ActiveMeetingMemberListViewController {
    func configureTableView() {
        tableView.register(ActiveMeetingMemberTableViewCell.self, forCellReuseIdentifier: ActiveMeetingMemberTableViewCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = dataSource
        tableView.allowsSelection = true
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 80
        tableView.delaysContentTouches = false
    }

    func pin(cellAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ActiveMeetingMemberTableViewCell {
            cell.pin()
        }
    }

    func unpin(cellAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ActiveMeetingMemberTableViewCell {
            cell.unpin()
        }
    }

    /// Sets focused member for the main view video preview layer
    func setDefaultFocusedMemberIfPossible() {
        guard tableView.indexPathForSelectedRow == nil else {
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

    func reload(data: [RoomMember], indexPathForSelectedRow: IndexPath?) {
        title = "(\(data.count))"
        dataSource.members = data
        tableView.reloadData()

        if let indexPath = indexPathForSelectedRow {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            select(indexPath)
        } else {
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

            // Check if cell is selected in tableview (selected cell represents the pinned member).
            guard let indexPath = self.tableView.indexPathForSelectedRow else {
                // No cell is selected.
                self.dataSource.members = list
                self.reload(data: list, indexPathForSelectedRow: nil)
                return
            }

            // Retrieve the member instance for the selected cell
            let member = self.dataSource.members[indexPath.row]

            // Search for the new index of the member in the received member list array.
            // This new member list array will replace the currently used member list.
            // By searching for the member inside the new list, we can calculate where it will be located in the tableview.
            guard let index = list.firstIndex(where: { $0 == member }) else {
                // Member does not exist inside the new member list, apparently it disconnected.
                self.dataSource.members = list
                self.reload(data: list, indexPathForSelectedRow: nil)
                return
            }

            // Update the currently selected indexPath with the new row index.
            var indexPathForSelectedRow = indexPath
            indexPathForSelectedRow.row = index

            // Reload the list.
            self.reload(data: list, indexPathForSelectedRow: indexPathForSelectedRow)
        }
    }
}

// MARK: - MemberFocusDelegate
extension ActiveMeetingMemberListViewController: MemberFocusDelegate {
    func memberObtainedFocus(_ member: RoomMember) {
        // do nothing
    }

    func memberLostFocus(_ member: RoomMember) {
        // In cases when the user has not pinned any member, but the focus changes to other members automatically,
        // we need to reload the previously focused member video configuration.
        if let indexPath = dataSource.indexPath(of: member) {
            if let cell = tableView.cellForRow(at: indexPath) as? ActiveMeetingMemberTableViewCell {
                cell.configureVideo()
            }
        }
    }
}
