//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

public protocol JoinedRoomChatDelegate: AnyObject {
    func chatMessagesDidChange(_ messages: [RoomChatMessage])
}
