//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Combine
import Foundation
import PhenixCore

extension ActiveMeetingChatViewController {
    class ViewModel {
        private let chatMimeType = ""

        private let core: PhenixCore
        private let session: AppSession
        private let preferences: Preferences

        private var cancellables = Set<AnyCancellable>()

        private lazy var meetingCode: String = {
            guard let meetingCode = preferences.currentMeetingCode else {
                fatalError("Meeting code is required to be provided.")
            }
            return meetingCode
        }()

        let messagesPublisher: AnyPublisher<[ChatMessage], Never>

        var displayName: String { preferences.displayName }

        init(core: PhenixCore, session: AppSession, preferences: Preferences) {
            self.core = core
            self.session = session
            self.preferences = preferences

            self.messagesPublisher = core.messagesPublisher
                .flatMap { messages in
                    messages.publisher
                        .map(ChatMessage.init)
                        .collect()
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()

            subscribeForEvents()
        }

        func send(_ message: String) {
            core.sendMessage(alias: meetingCode, message: message, mimeType: chatMimeType)
        }

        private func subscribeForEvents() {
            let configuration = PhenixCore.Message.Configuration(batchSize: 0, mimeType: chatMimeType)
            core.subscribeToMessages(alias: meetingCode, configuration: configuration)
        }
    }
}
