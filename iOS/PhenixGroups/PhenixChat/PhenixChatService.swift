//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixSdk

public class PhenixChatService {
    private let chatService: PhenixRoomChatService
    private let queue: DispatchQueue
    private var chatMessagesDisposable: PhenixDisposable?

    public weak var delegate: PhenixChatServiceDelegate?

    public init(roomService: PhenixRoomService) {
        queue = DispatchQueue(label: "com.phenixrts.suite.groups.PhenixChatService", qos: .userInitiated)
        chatService = PhenixRoomChatServiceFactory.createRoomChatService(roomService)
    }

    public func subscribe() {
        queue.async { [weak self] in
            guard let self = self else { return }
            os_log(.debug, log: .chatService, "Subscribe to chat updates")
            self.chatMessagesDisposable = self.chatService.getObservableChatMessages().subscribe(self.chatMessagesDidChange)
        }
    }

    public func send(_ message: String) {
        queue.async { [weak self] in
            os_log(.debug, log: .chatService, "Send chat message")
            self?.chatService.sendMessage(toRoom: message)
        }
    }

    public func dispose() {
        chatMessagesDisposable = nil
    }
}

// MARK: - Internal methods
internal extension PhenixChatService {
    func deliver(_ messages: [PhenixRoomChatMessage]) {
        os_log(.debug, log: .chatService, "Deliver chat messages to the delegate")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.chatService(self, didReceive: messages)
        }
    }
}

// MARK: - Private methods
private extension PhenixChatService {
    func chatMessagesDidChange(_ changes: PhenixObservableChange<NSArray>?) {
        queue.async { [weak self] in
            guard let chatMessages = changes?.value as? [PhenixChatMessage] else { return }

            os_log(.debug, log: .chatService, "Did receive chat message update")

            let messages = chatMessages.compactMap(PhenixRoomChatMessage.init)

            self?.deliver(messages)
        }
    }
}
