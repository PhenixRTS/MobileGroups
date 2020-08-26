//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import UIKit

protocol MeetingHistoryDelegate: AnyObject {
    func rejoin(_ meeting: Meeting)
}

protocol MeetingHistoryViewDelegate: AnyObject {
    func tableContentSizeDidChange(_ size: CGSize)
}

class MeetingHistoryTableViewController: UITableViewController, Storyboarded {
    typealias RejoinHandler = (Meeting) -> Void
    typealias LoadMeetings = () -> [Meeting]

    private var dataSource = MeetingHistoryTableDataSource()
    weak var delegate: MeetingHistoryDelegate?
    weak var viewDelegate: MeetingHistoryViewDelegate?

    var loadMeetingsHandler: LoadMeetings!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()

        dataSource.rejoinHandler = { [weak delegate] meeting in
            delegate?.rejoin(meeting)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        dataSource.meetings = loadMeetingsHandler()
        tableView.reloadData()

        viewDelegate?.tableContentSizeDidChange(tableView.contentSize)
    }

    func set(_ meetings: [Meeting]) {
        dataSource.meetings = meetings
        os_log(.debug, log: .newMeetingScene, "%{PUBLIC}d meetings set to history data source", meetings.count)
    }

    func add(_ meeting: Meeting) {
        dataSource.meetings.insert(meeting, at: 0)
        if dataSource.meetings.count > 3 {
            tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        } else {
            tableView.reloadData()
        }
        viewDelegate?.tableContentSizeDidChange(tableView.contentSize)

        os_log(.debug, log: .newMeetingScene, "Added meeting to history data source")
    }
}

private extension MeetingHistoryTableViewController {
    func configureTableView() {
        tableView.dataSource = dataSource
        tableView.register(MeetingHistoryTableViewCell.self, forCellReuseIdentifier: MeetingHistoryTableViewCell.identifier)
        tableView.estimatedRowHeight = 62
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delaysContentTouches = false
        tableView.allowsSelection = false
    }
}
