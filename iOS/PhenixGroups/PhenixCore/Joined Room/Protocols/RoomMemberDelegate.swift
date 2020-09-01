//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import PhenixSdk

internal protocol RoomMemberDelegate: AnyObject {
    func memberStreamDidChange(_ member: RoomMember, streams: [PhenixStream])
}
