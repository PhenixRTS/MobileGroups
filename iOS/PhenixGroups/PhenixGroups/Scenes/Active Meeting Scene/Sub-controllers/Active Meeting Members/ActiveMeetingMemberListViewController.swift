//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

class ActiveMeetingMemberListViewController: UITableViewController {
    private static let maxVideoSubscriptions = 3
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
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delaysContentTouches = false
        tableView.allowsSelection = false
        tableView.tableFooterView = UIView()
    }
}

extension ActiveMeetingMemberListViewController: JoinedRoomMembersDelegate {
    func memberListDidChange(_ list: [RoomMember]) {
        dataSource.members = list

        // Calculate how many of members have video subscriptions at the moment.
        var videoSubscriptions = list.reduce(into: 0) { result, member in
            result += member.subscriptionType == .some(.video) ? 1 : 0
        }

        list.forEach { member in
            if member.isSubscribed == false {
                if videoSubscriptions + 1 < Self.maxVideoSubscriptions {
                    videoSubscriptions += 1
                    member.subscribe(for: .video)
                } else {
                    member.subscribe(for: .audio)
                }
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
}
