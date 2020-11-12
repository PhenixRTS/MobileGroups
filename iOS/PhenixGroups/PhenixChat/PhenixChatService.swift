//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixSdk

public class PhenixChatService {
    private let chatService: PhenixRoomChatService
    private var chatMessagesDisposable: PhenixDisposable?

    public weak var delegate: PhenixChatServiceDelegate?

    public init(roomService: PhenixRoomService) {
        chatService = PhenixRoomChatServiceFactory.createRoomChatService(roomService)
    }

    public func subscribe() {
        os_log(.debug, log: .chatService, "Subscribe to chat updates")
        chatMessagesDisposable = chatService.getObservableChatMessages()?.subscribe(chatMessagesDidChange)
    }

    public func send(_ message: String) {
        os_log(.debug, log: .chatService, "Send chat message")
        chatService.sendMessage(toRoom: message)
    }

    public func dispose() {
        chatMessagesDisposable = nil
    }
}

// MARK: - Internal methods
internal extension PhenixChatService {
    func deliver(_ messages: [PhenixRoomChatMessage]) {
        os_log(.debug, log: .chatService, "Deliver chat messages to the delegate")
        delegate?.chatService(self, didReceive: messages)
    }
}

// MARK: - Private methods
private extension PhenixChatService {
    func chatMessagesDidChange(_ changes: PhenixObservableChange<NSArray>?) {
        guard let chatMessages = changes?.value as? [PhenixChatMessage] else {
            return
        }

        os_log(.debug, log: .chatService, "Did receive chat message update")

        let messages = chatMessages.compactMap(PhenixRoomChatMessage.init)

        deliver(messages)
    }
}
