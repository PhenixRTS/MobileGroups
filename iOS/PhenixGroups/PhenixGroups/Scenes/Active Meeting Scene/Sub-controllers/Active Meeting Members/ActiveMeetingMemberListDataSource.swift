//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import UIKit

class ActiveMeetingMemberListDataSource: NSObject, UITableViewDataSource {
    var members = [RoomMember]()

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { members.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ActiveMeetingMemberTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        let member = members[indexPath.row]
        member.delegate = cell
        cell.configure(displayName: member.screenName, cameraEnabled: member.isVideoAvailable)
        cell.setCamera(member.previewLayer)
        return cell
    }
}
