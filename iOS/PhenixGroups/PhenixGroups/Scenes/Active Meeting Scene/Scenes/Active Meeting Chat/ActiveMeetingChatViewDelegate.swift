//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

protocol ActiveMeetingChatViewDelegate: AnyObject {
    func totalNumberOfRows() -> Int?
    func activeMeetingChatView(_ view: ActiveMeetingChatView, didTapSendMessageButtonWithText text: String)
}
