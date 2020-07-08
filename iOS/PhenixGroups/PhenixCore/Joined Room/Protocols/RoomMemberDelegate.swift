//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

public protocol RoomMemberDelegate: AnyObject {
    func roomMemberAudioStateDidChange(_ member: RoomMember, enabled: Bool)
    func roomMemberVideoStateDidChange(_ member: RoomMember, enabled: Bool)
}
