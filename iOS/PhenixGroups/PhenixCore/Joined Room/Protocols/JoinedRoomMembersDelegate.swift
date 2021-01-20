//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

public protocol JoinedRoomMembersDelegate: AnyObject {
    func memberListDidChange(_ list: [RoomMember])
}
