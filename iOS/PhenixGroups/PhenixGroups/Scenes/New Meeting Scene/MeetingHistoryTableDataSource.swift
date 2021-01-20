//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class MeetingHistoryTableDataSource: NSObject, UITableViewDataSource {
    typealias RejoinHandler = MeetingHistoryTableViewController.RejoinHandler

    var meetings = [Meeting]()
    var rejoinHandler: RejoinHandler?

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        meetings.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: MeetingHistoryTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        cell.configure(with: meetings[indexPath.row], rejoin: rejoinHandler)
        return cell
    }
}
