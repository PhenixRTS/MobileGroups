//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Combine
import os.log
import UIKit

protocol MeetingHistoryTableViewControllerDelegate: AnyObject {
    func join(_ meeting: Meeting)
}

protocol MeetingHistoryTableViewDelegate: AnyObject {
    func tableContentSizeDidChange(_ size: CGSize)
}

class MeetingHistoryTableViewController: UITableViewController, Storyboarded {
    private static let logger = OSLog(identifier: "MeetingHistoryTableViewController")

    var dataSource: DataSource!

    weak var delegate: MeetingHistoryTableViewControllerDelegate?
    weak var viewDelegate: MeetingHistoryTableViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(dataSource != nil, "DataSource should exist!")

        configureTableView()

        dataSource.onJoin = { [weak delegate] meeting in
            delegate?.join(meeting)
        }

        dataSource.onDataUpdate = { [weak self] in
            guard let self = self else {
                return
            }

            self.viewDelegate?.tableContentSizeDidChange(self.tableView.contentSize)
        }

        dataSource.setTableView(tableView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDelegate?.tableContentSizeDidChange(tableView.contentSize)
    }

    func observeMeetings() {
        dataSource.observeMeetings()
    }

    // MARK: - Private methods

    private func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.allowsSelection = false
        tableView.estimatedRowHeight = 62
        tableView.delaysContentTouches = false
    }
}
