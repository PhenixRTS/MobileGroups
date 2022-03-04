//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Combine
import os.log
import PhenixCore
import UIKit

class ActiveMeetingMemberListViewController: UIViewController, PageContainerMember {
    // swiftlint:disable:next force_cast
    private var contentView: ActiveMeetingMemberListView { view as! ActiveMeetingMemberListView }
    private var memberListCancellable: AnyCancellable?

    var viewModel: ViewModel!
    var dataSource: DataSource!

    lazy var pageIcon = UIImage(systemName: "person.3")

    override func loadView() {
        let view = ActiveMeetingMemberListView()
        view.delegate = self

        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(viewModel != nil, "ViewModel should exist!")
        assert(dataSource != nil, "DataSource should exist!")

        dataSource.setTableView(contentView.tableView)

        memberListCancellable = viewModel.membersPublisher
            .sink { [weak self] members in
                self?.title = "(\(members.count))"
                self?.dataSource.updateData(members)
            }

        viewModel.subscribeToMembers()
    }
}

// MARK: - ActiveMeetingMemberListViewDelegate
extension ActiveMeetingMemberListViewController: ActiveMeetingMemberListViewDelegate {
    func activeMeetingMemberListView(_ view: ActiveMeetingMemberListView, didSelectMemberCellAt indexPath: IndexPath) {
        if let member = dataSource.member(for: indexPath) {
            viewModel.select(member)
        }
    }

    func activeMeetingMemberListView(
        _ view: ActiveMeetingMemberListView,
        didDeselectMemberCellAt indexPath: IndexPath
    ) {
        if let member = dataSource.member(for: indexPath) {
            viewModel.deselect(member)
        }
    }
}
