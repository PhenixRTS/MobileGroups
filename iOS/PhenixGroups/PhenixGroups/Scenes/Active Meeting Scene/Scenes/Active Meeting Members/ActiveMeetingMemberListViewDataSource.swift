//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixCore
import UIKit

extension ActiveMeetingMemberListViewController {
    class DataSource {
        // swiftlint:disable:next nesting
        private typealias DataSource = UITableViewDiffableDataSource<Section, PhenixCore.Member>

        private let core: PhenixCore

        private var tableView: UITableView?
        private var dataSource: DataSource?

        init(core: PhenixCore) {
            self.core = core
        }

        func member(for indexPath: IndexPath) -> PhenixCore.Member? {
            dataSource?.itemIdentifier(for: indexPath)
        }

        func indexPath(for member: PhenixCore.Member) -> IndexPath? {
            dataSource?.indexPath(for: member)
        }

        func setTableView(_ tableView: UITableView) {
            self.tableView = tableView
            registerCells(for: tableView)
            dataSource = registerDataSource(for: tableView)
        }

        func updateData(_ data: [PhenixCore.Member]) {
            var snapshot = NSDiffableDataSourceSnapshot<Section, PhenixCore.Member>()

            snapshot.appendSections(Section.allCases)
            snapshot.appendItems(data, toSection: .all)

            dataSource?.apply(snapshot, animatingDifferences: false)
        }

        func reloadData(for data: PhenixCore.Member) {
            guard let dataSource = dataSource else {
                return
            }

            var snapshot = dataSource.snapshot()
            snapshot.reloadItems([data])
            dataSource.apply(snapshot, animatingDifferences: false)
        }

        private func registerCells(for tableView: UITableView) {
            tableView.register(
                ActiveMeetingMemberListTableViewCell.self,
                forCellReuseIdentifier: ActiveMeetingMemberListTableViewCell.identifier
            )
        }

        private func registerDataSource(for tableView: UITableView) -> DataSource {
            let dataSource = makeDataSource(for: tableView)
            tableView.dataSource = dataSource
            return dataSource
        }

        private func makeDataSource(for tableView: UITableView) -> DataSource {
            UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, member in
                guard let self = self else {
                    return nil
                }

                let cell: ActiveMeetingMemberListTableViewCell = tableView.dequeueReusableCell(for: indexPath)

                let viewModel = ActiveMeetingMemberListTableViewCell.ViewModel(core: self.core, member: member)
                cell.configure(viewModel: viewModel)

                return cell
            }
        }
    }
}

extension ActiveMeetingMemberListViewController.DataSource {
    enum Section: CaseIterable {
        case all
    }
}
