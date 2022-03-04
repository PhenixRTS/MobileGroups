//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Combine
import UIKit

extension MeetingHistoryTableViewController {
    class DataSource {
        // swiftlint:disable:next nesting
        private typealias DataSource = UITableViewDiffableDataSource<Section, Meeting>

        private let preferences: Preferences

        private var tableView: UITableView?
        private var dataSource: DataSource?
        private var cancellable: AnyCancellable?

        var onJoin: ((Meeting) -> Void)?
        var onDataUpdate: (() -> Void)?

        init(preferences: Preferences) {
            self.preferences = preferences
        }

        func setTableView(_ tableView: UITableView) {
            self.tableView = tableView
            registerCells(for: tableView)
            dataSource = registerDataSource(for: tableView)
        }

        func observeMeetings() {
            cancellable = preferences.meetingsPublisher
                .map { meetings in
                    meetings.sorted { $0.leaveDate > $1.leaveDate }
                }
                .sink { [weak self] meetings in
                    self?.updateData(meetings) {
                        self?.onDataUpdate?()
                    }
                }
        }

        private func updateData(_ data: [Meeting], completion: (() -> Void)? = nil) {
            var snapshot = NSDiffableDataSourceSnapshot<Section, Meeting>()

            snapshot.appendSections(Section.allCases)
            snapshot.appendItems(data, toSection: .all)

            dataSource?.apply(snapshot, completion: completion)
        }

        private func registerCells(for tableView: UITableView) {
            tableView.register(
                MeetingHistoryTableViewCell.self,
                forCellReuseIdentifier: MeetingHistoryTableViewCell.identifier
            )
        }

        private func registerDataSource(for tableView: UITableView) -> DataSource {
            let dataSource = makeDataSource(for: tableView)
            tableView.dataSource = dataSource
            return dataSource
        }

        private func makeDataSource(for tableView: UITableView) -> DataSource {
            UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, meeting in
                guard let self = self else {
                    return nil
                }

                let cell: MeetingHistoryTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.configure(with: meeting) { [weak self] meeting in
                    self?.onJoin?(meeting)
                }

                return cell
            }
        }
    }
}

extension MeetingHistoryTableViewController.DataSource {
    enum Section: CaseIterable {
        case all
    }
}
