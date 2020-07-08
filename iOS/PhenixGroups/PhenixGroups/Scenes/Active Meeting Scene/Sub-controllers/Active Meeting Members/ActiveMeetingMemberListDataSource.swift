//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

class ActiveMeetingMemberListDataSource: NSObject, UITableViewDataSource {
    var members = [RoomMember]()
    var pinnedMember: RoomMember?
    var indexPathForSelectedRow: IndexPath?

    func indexPath(of member: RoomMember) -> IndexPath? {
        if let index = members.firstIndex(of: member) {
            return IndexPath(row: index, section: 0)
        }

        return nil
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { members.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ActiveMeetingMemberTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        let member = members[indexPath.row]

        cell.configure(member: member)

        if member == pinnedMember {
            cell.pin()
        }

        return cell
    }

    func pin(_ cell: ActiveMeetingMemberTableViewCell, at indexPath: IndexPath) {
        pinnedMember = members[indexPath.row]
        cell.pin()
    }

    func unpin(_ cell: ActiveMeetingMemberTableViewCell, at indexPath: IndexPath) {
        pinnedMember = nil
        cell.unpin()
    }
}
