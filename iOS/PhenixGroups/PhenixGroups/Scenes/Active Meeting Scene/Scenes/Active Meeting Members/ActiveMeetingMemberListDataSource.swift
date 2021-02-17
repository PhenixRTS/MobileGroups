//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

class ActiveMeetingMemberListDataSource: NSObject, UITableViewDataSource {
    var members = [RoomMember]()

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
        cell.configureAudio()

        if indexPath == tableView.indexPathForSelectedRow {
            cell.pin()
        }

        return cell
    }
}
