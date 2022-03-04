//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

extension ActiveMeetingChatViewController {
    class DataSource {
        // swiftlint:disable:next nesting
        private typealias DataSource = UITableViewDiffableDataSource<Section, ChatMessage>

        private let preferences: Preferences

        private var tableView: UITableView?
        private var dataSource: DataSource?

        var totalNumberOfRows: Int? {
            dataSource?.snapshot().numberOfItems
        }

        init(preferences: Preferences) {
            self.preferences = preferences
        }

        func setTableView(_ tableView: UITableView) {
            self.tableView = tableView
            registerCells(for: tableView)
            dataSource = registerDataSource(for: tableView)
        }

        func updateData(_ data: [ChatMessage]) {
            var snapshot = NSDiffableDataSourceSnapshot<Section, ChatMessage>()

            snapshot.appendSections(Section.allCases)
            snapshot.appendItems(data, toSection: .all)

            dataSource?.apply(snapshot)
        }

        // MARK: - Private methods

        private func registerCells(for tableView: UITableView) {
            tableView.register(
                ActiveMeetingChatTableViewCell.self,
                forCellReuseIdentifier: ActiveMeetingChatTableViewCell.identifier
            )
        }

        private func registerDataSource(for tableView: UITableView) -> DataSource {
            let dataSource = makeDataSource(for: tableView)
            tableView.dataSource = dataSource
            return dataSource
        }

        private func makeDataSource(for tableView: UITableView) -> DataSource {
            UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, message in
                guard let self = self else {
                    return nil
                }

                let cell: ActiveMeetingChatTableViewCell = tableView.dequeueReusableCell(for: indexPath)

                let viewModel = ActiveMeetingChatTableViewCell.ViewModel(
                    preferences: self.preferences,
                    message: message
                )
                cell.configure(viewModel: viewModel)

                return cell
            }
        }
    }
}

extension ActiveMeetingChatViewController.DataSource {
    enum Section: CaseIterable {
        case all
    }
}
