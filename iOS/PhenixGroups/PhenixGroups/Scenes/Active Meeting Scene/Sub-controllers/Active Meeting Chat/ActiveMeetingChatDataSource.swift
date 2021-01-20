//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixChat
import UIKit

class ActiveMeetingChatDataSource: NSObject, UITableViewDataSource {
    var messages = [PhenixRoomChatMessage]()

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ActiveMeetingChatTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        let message = messages[indexPath.row]

        cell.configure(message: message)

        return cell
    }
}
