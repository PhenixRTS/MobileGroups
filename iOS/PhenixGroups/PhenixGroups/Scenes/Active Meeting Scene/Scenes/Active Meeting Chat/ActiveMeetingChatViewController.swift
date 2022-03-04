//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Combine
import PhenixCore
import UIKit

class ActiveMeetingChatViewController: UIViewController, PageContainerMember {
    typealias SendMessageHandler = (String) -> Void

    // swiftlint:disable:next force_cast
    private var contentView: ActiveMeetingChatView { view as! ActiveMeetingChatView }
    private var cancellable: AnyCancellable?

    var viewModel: ViewModel!
    var dataSource: DataSource!

    lazy var pageIcon = UIImage(systemName: "message")

    override func loadView() {
        let view = ActiveMeetingChatView()
        view.delegate = self

        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(viewModel != nil, "ViewModel should exist!")
        assert(dataSource != nil, "DataSource should exist!")

        dataSource.setTableView(contentView.tableView)

        cancellable = viewModel.messagesPublisher
            .sink { [weak self] messages in
                self?.title = "(\(messages.count))"
                self?.dataSource.updateData(messages)
                self?.contentView.scrollToBottom()
            }
    }
}

// MARK: - ActiveMeetingChatViewDelegate
extension ActiveMeetingChatViewController: ActiveMeetingChatViewDelegate {
    func totalNumberOfRows() -> Int? {
        dataSource.totalNumberOfRows
    }

    func activeMeetingChatView(_ view: ActiveMeetingChatView, didTapSendMessageButtonWithText text: String) {
        viewModel.send(text)
    }
}
