//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

class ActiveMeetingChatDataSource: NSObject, UITableViewDataSource {
    var messages = [String]()

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 20 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ActiveMeetingChatTableViewCell = tableView.dequeueReusableCell(for: indexPath)

        cell.configure(author: "You", message: "Test\(indexPath.row)", date: Date().addingTimeInterval(TimeInterval(indexPath.row * -30)))

        return cell
    }
}
