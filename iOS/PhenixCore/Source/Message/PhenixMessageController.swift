//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Combine
import Foundation
import os.log
import PhenixSdk

extension PhenixCore {
    final class MessageController {
        fileprivate typealias Alias = String
        fileprivate typealias MimeType = String

        private static let logger = OSLog(identifier: "MessageController")

        private let queue: DispatchQueue

        private var services: [Alias: [MimeType: MessageServiceContainer]]

        // MARK: - Subjects
        private var eventSubject = PassthroughSubject<Message.Event, Never>()
        private var messageSubject = CurrentValueSubject<[Message], Never>([])

        // MARK: - Publishers
        lazy var eventPublisher = eventSubject.eraseToAnyPublisher()
        lazy var messagesPublisher = messageSubject.eraseToAnyPublisher()

        var messages: [Message] { messageSubject.value }

        init(queue: DispatchQueue = .main) {
            self.queue = queue
            self.services = [:]
        }

        func subscribeForMessages(
            alias: String,
            roomService: PhenixRoomService,
            configuration: Message.Configuration
        ) {
            guard service(for: alias, mimeType: configuration.mimeType) == nil else {
                os_log(
                    .debug,
                    log: Self.logger,
                    "%{private}s Messages already subscribed for mime-type: %{private}s",
                    alias,
                    configuration.mimeType
                )
                return
            }

            do {
                let service = try makeChatService(roomService: roomService, configuration: configuration)
                let disposable = observeMessages(alias: alias, service: service, mimeType: configuration.mimeType)

                let serviceContainer = MessageServiceContainer(service: service, lastChatMessageDisposable: disposable)
                services[alias, default: [:]].updateValue(serviceContainer, forKey: configuration.mimeType)

                os_log(
                    .debug,
                    log: Self.logger,
                    "%{private}s Messages subscribed successfully for mime-type: %{private}s",
                    alias,
                    configuration.mimeType
                )

                eventSubject.send(.messageSubscriptionSucceeded)
            } catch {
                os_log(
                    .debug,
                    log: Self.logger,
                    "%{private}s Message subscription failed for mime-type: %{private}s",
                    alias,
                    configuration.mimeType
                )

                eventSubject.send(.messageSubscriptionFailed)
            }
        }

        /// Unsubscribe from a specific chat service associated with a ``PhenixCore/PhenixCore/Channel`` or ``PhenixCore/PhenixCore/Room``
        /// alias and a specific mimeType.
        ///
        /// It will also remove all messages received from the provided alias and mime-type.
        ///
        /// - Parameters:
        ///   - alias: Channel or room alias.
        ///   - mimeType: Chat service mime type.
        func unsubscribeMessages(alias: String, mimeType: String) {
            if let _ = services[alias]?.removeValue(forKey: mimeType) {
                os_log(
                    .debug,
                    log: Self.logger,
                    "%{private}s Unsubscribed to messages for mime type: %{private}s",
                    alias,
                    mimeType
                )
            }

            if services[alias]?.isEmpty == true {
                // If there are no more services provided for the
                // specific alias, there is no point to keep this
                // key-value pair in the dictionary anymore.
                services.removeValue(forKey: alias)
            }

            removeMessages(withAlias: alias, mimeType: mimeType)
        }

        /// Unsubscribe from all chat services associated with a ``PhenixCore/PhenixCore/Channel`` or ``PhenixCore/PhenixCore/Room``
        /// alias.
        ///
        /// It will also remove all messages received from the provided alias.
        ///
        /// - Parameter alias: Channel or room alias.
        func unsubscribeAllMessages(alias: String) {
            if let _ = services.removeValue(forKey: alias) {
                os_log(.debug, log: Self.logger, "%{private}s Unsubscribed to all messages", alias)
            }

            removeMessages(withAlias: alias)
        }

        func sendMessage(alias: String, message: String, mimeType: String) {
            os_log(
                .debug,
                log: Self.logger,
                "Send chat message, mimeType: %{private}s, message: %{private}s",
                mimeType,
                message
            )

            guard let service = service(for: alias, mimeType: mimeType) else {
                os_log(
                    .error,
                    log: Self.logger,
                    "Chat service for alias: %{private}s with mimeType: %{private}s does not exist. Message not sent.",
                    alias,
                    mimeType
                )
                eventSubject.send(.messageSubscriptionNotFound)
                return
            }

            let callback: ((PhenixRequestStatus, String?) -> Void) = { status, description in
                os_log(
                    .debug,
                    log: Self.logger,
                    """
                    Sent chat message status: %{private}s (%{private}s); \
                    mime type: %{private}s; \
                    message: %{private}s
                    """,
                    status.description,
                    description ?? "-",
                    mimeType,
                    message
                )
            }

            /*
             When sending a chat message we must not
             forget to provide also a mime type to
             which the message will be sent, without
             it the message will not be delivered to
             the intended mime type.
             */
            if mimeType.isEmpty {
                service.sendMessage(toRoom: message) { status, description in
                    callback(status, description)
                }
            } else {
                service.sendMessage(toRoom: message, mimeType) { status, description in
                    callback(status, description)
                }
            }
        }

        // MARK: - Private methods

        private func makeChatService(
            roomService: PhenixRoomService,
            configuration: Message.Configuration
        ) throws -> PhenixRoomChatService {
            let size = configuration.batchSize
            let mimeTypes: [String] = configuration.mimeType.isEmpty ? [] : [configuration.mimeType]

            let service: PhenixRoomChatService? = {
                if mimeTypes.isEmpty {
                    return PhenixRoomChatServiceFactory.createRoomChatService(roomService)
                } else {
                    return PhenixRoomChatServiceFactory.createRoomChatService(roomService, size, mimeTypes)
                }
            }()

            guard let service = service else {
                throw Error.chatServiceCreationFailed
            }

            return service
        }

        private func observeMessages(
            alias: String,
            service: PhenixRoomChatService,
            mimeType: String
        ) -> PhenixDisposable {
            service
                .getObservableLastChatMessage()
                .subscribe { [weak self] changes in
                    self?.lastChatMessagesDidChange(changes, alias: alias)
                }
        }

        private func lastChatMessagesDidChange(_ changes: PhenixObservableChange<PhenixChatMessage>?, alias: String) {
            queue.async { [weak self] in
                guard let self = self else {
                    return
                }

                guard let phenixMessage = changes?.value else {
                    return
                }

                self.process(phenixMessage: phenixMessage, alias: alias)
            }
        }

        private func process(phenixMessage: PhenixChatMessage, alias: String?) {
            guard let message = PhenixCore.Message(phenixMessage) else {
                return
            }

            // Provide an alias of the room/channel to the message, so that it would
            // be possible to remove it afterwards if the user leaves the room/channel.
            message.alias = alias

            os_log(.debug, log: Self.logger, "Raw chat message received: %{private}s", message.debugDescription)

            messageSubject.value.append(message)
        }

        private func service(for alias: Alias, mimeType: MimeType) -> PhenixRoomChatService? {
            services[alias]?[mimeType]?.service
        }

        private func removeMessages(withAlias alias: String, mimeType: String? = nil) {
            let filteredMessages = messageSubject.value.filter { $0.alias != alias && $0.mimeType != mimeType }
            messageSubject.send(filteredMessages)
        }
    }
}

// MARK: - Disposable
extension PhenixCore.MessageController: Disposable {
    func dispose() {
        os_log(.debug, log: Self.logger, "Dispose")

        services.removeAll()
        messageSubject.send([])
    }
}
