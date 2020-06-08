//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

class ActiveMeetingMemberListViewController: UITableViewController {
    private let dataSource = ActiveMeetingMemberListDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
    }
}

private extension ActiveMeetingMemberListViewController {
    func configureTableView() {
        tableView.dataSource = dataSource
        tableView.register(ActiveMeetingMemberTableViewCell.self, forCellReuseIdentifier: ActiveMeetingMemberTableViewCell.identifier)
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delaysContentTouches = false
        tableView.allowsSelection = false
        tableView.tableFooterView = UIView()
    }
}

extension ActiveMeetingMemberListViewController: JoinedRoomMembersDelegate {
    func memberListDidChange(_ list: [String]) {
        dataSource.members = list
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
}
