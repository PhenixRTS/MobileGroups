//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

public protocol PhenixChatServiceDelegate: AnyObject {
    func chatService(_ service: PhenixChatService, didReceive messages: [PhenixRoomChatMessage])
}
