//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixChat

public protocol ChatProvider: AnyObject {
    var chatService: PhenixChatService { get }

    func send(message: String)
    func subscribeToChatMessages(_ delegate: PhenixChatServiceDelegate)
}

public extension ChatProvider {
    func send(message: String) {
        os_log(.debug, log: .joinedRoom, "Send chat message")
        chatService.send(message)
    }

    func subscribeToChatMessages(_ delegate: PhenixChatServiceDelegate) {
        os_log(.debug, log: .joinedRoom, "Subscribe to chat message updates with delegate")
        chatService.delegate = delegate
        chatService.subscribe()
    }
}
