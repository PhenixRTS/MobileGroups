//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import UIKit

class ActiveMeetingMemberListView: UIView {
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.allowsSelection = true
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 80
        tableView.delaysContentTouches = false
        return tableView
    }()

    weak var delegate: ActiveMeetingMemberListViewDelegate?

    override init(frame: CGRect) {
         super.init(frame: frame)
         setup()
    }

    required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
         setup()
    }

    private func setup() {
        addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDelegate
extension ActiveMeetingMemberListView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath == tableView.indexPathForSelectedRow {
            // Trying to select the same cell which is already selected - deselect this cell.
            tableView.deselectRow(at: indexPath, animated: false)
            delegate?.activeMeetingMemberListView(self, didDeselectMemberCellAt: indexPath)
            return nil
        } else {
            return indexPath
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.activeMeetingMemberListView(self, didSelectMemberCellAt: indexPath)
    }
}
