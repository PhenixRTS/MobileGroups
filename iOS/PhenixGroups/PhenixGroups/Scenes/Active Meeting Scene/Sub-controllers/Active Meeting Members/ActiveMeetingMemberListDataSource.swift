//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class ActiveMeetingMemberListDataSource: NSObject, UITableViewDataSource {
    var members = [String]()

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { members.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ActiveMeetingMemberTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        cell.configure(displayName: members[indexPath.row])
        return cell
    }
}
