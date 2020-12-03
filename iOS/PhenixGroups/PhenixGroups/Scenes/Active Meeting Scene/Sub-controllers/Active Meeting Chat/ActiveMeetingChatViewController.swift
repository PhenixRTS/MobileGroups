//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixChat
import PhenixCore
import UIKit

class ActiveMeetingChatViewController: UIViewController, PageContainerMember {
    typealias SendMessageHandler = (String) -> Void

    private var timer: Timer?

    var displayName: String!
    lazy var dataSource = ActiveMeetingChatDataSource()
    lazy var pageIcon = UIImage(named: "meeting_chat_icon")

    var activeMeetingChatView: ActiveMeetingChatView {
        view as! ActiveMeetingChatView
    }

    var sendMessageHandler: SendMessageHandler? {
        didSet {
            activeMeetingChatView.sendMessageHandler = sendMessageHandler
        }
    }

    override func loadView() {
        view = ActiveMeetingChatView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(displayName != nil, "Display name is required!")

        configureTableView()

        let timer = Timer(timeInterval: 1.0, target: self, selector: #selector(refreshDates), userInfo: nil, repeats: true)
        self.timer = timer
        timer.tolerance = 0.2
        RunLoop.current.add(timer, forMode: .common) // So that timer would get fired even if user is interacting with UI at the current moment.
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate()
    }
}

private extension ActiveMeetingChatViewController {
    func configureTableView() {
        activeMeetingChatView.tableView.dataSource = dataSource
        activeMeetingChatView.tableView.register(ActiveMeetingChatTableViewCell.self, forCellReuseIdentifier: ActiveMeetingChatTableViewCell.identifier)
        activeMeetingChatView.tableView.estimatedRowHeight = 20
        activeMeetingChatView.tableView.rowHeight = UITableView.automaticDimension
        activeMeetingChatView.tableView.allowsSelection = false
        activeMeetingChatView.tableView.separatorStyle = .none
        activeMeetingChatView.tableView.keyboardDismissMode = .onDrag
        activeMeetingChatView.tableView.tableFooterView = UIView()
    }

    @objc
    func refreshDates() {
        activeMeetingChatView.tableView.visibleCells
            .compactMap { $0 as? ActiveMeetingChatTableViewCell }
            .forEach { $0.refreshDateRepresentation() }
    }
}

// MARK: - JoinedRoomChatDelegate
extension ActiveMeetingChatViewController: PhenixChatServiceDelegate {
    func chatService(_ service: PhenixChatService, didReceive messages: [PhenixRoomChatMessage]) {
        for message in messages where message.authorName == displayName {
            message.maskAsYourself()
        }

        dataSource.messages = messages.sorted { $0.date < $1.date }
        activeMeetingChatView.reloadData()
    }
}
