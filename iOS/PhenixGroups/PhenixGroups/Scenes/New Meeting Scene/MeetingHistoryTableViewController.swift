//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

protocol MeetingHistoryDelegate: AnyObject {
    func tableContentSizeDidChange(_ size: CGSize)
}

class MeetingHistoryTableViewController: UITableViewController, Storyboarded {
    var dataSource = MeetingHistoryTableDataSource()
    weak var delegate: MeetingHistoryDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = dataSource
        delegate?.tableContentSizeDidChange(tableView.contentSize)
    }

    func addMeeting(_ meeting: String) {
        dataSource.meetings.append(meeting)
        tableView.reloadData()
        delegate?.tableContentSizeDidChange(tableView.contentSize)
    }
}
