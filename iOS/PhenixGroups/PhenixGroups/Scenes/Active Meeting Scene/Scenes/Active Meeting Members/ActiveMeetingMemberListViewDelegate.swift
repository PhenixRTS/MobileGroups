//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

protocol ActiveMeetingMemberListViewDelegate: AnyObject {
    /// Delegate method indicating that the member cell has been selected.
    func activeMeetingMemberListView(_ view: ActiveMeetingMemberListView, didSelectMemberCellAt indexPath: IndexPath)

    /// Delegate method indicating that the currently selected cell is being deselected.
    func activeMeetingMemberListView(_ view: ActiveMeetingMemberListView, didDeselectMemberCellAt indexPath: IndexPath)
}
