//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

class ActiveMeetingChatViewController: UIViewController, PageContainerMember {
    lazy var dataSource = ActiveMeetingChatDataSource()
    lazy var pageIcon = UIImage(named: "meeting_chat_icon")

    var activeMeetingChatView: ActiveMeetingChatView {
        view as! ActiveMeetingChatView
    }

    override func loadView() {
        view = ActiveMeetingChatView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        activeMeetingChatView.sendMessageHandler = { [weak self] message in
            self?.send(message: message)
        }
    }

    func send(message: String) {
        // TODO: Implement message sending
    }
}

private extension ActiveMeetingChatViewController {
    func configureTableView() {
        activeMeetingChatView.chatTableView.dataSource = dataSource
        activeMeetingChatView.chatTableView.register(ActiveMeetingChatTableViewCell.self, forCellReuseIdentifier: ActiveMeetingChatTableViewCell.identifier)
        activeMeetingChatView.chatTableView.estimatedRowHeight = 20
        activeMeetingChatView.chatTableView.rowHeight = UITableView.automaticDimension
        activeMeetingChatView.chatTableView.allowsSelection = false
        activeMeetingChatView.chatTableView.separatorStyle = .none
        activeMeetingChatView.chatTableView.keyboardDismissMode = .onDrag
        activeMeetingChatView.chatTableView.tableFooterView = UIView()
    }
}

extension ActiveMeetingChatViewController: JoinedRoomChatDelegate {
    func chatMessagesDidChange(_ messages: [RoomChatMessage]) {
        dataSource.messages = messages.sorted { $0.date < $1.date }
        DispatchQueue.main.async { [weak self] in
            self?.activeMeetingChatView.reloadData()
        }
    }
}
