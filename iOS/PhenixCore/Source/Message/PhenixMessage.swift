//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import PhenixSdk

public extension PhenixCore {
    final class Message: Identifiable {
        public var id: String
        public var message: String
        public var date: Date
        public var mimeType: String
        public var memberID: String
        public var memberName: String
        public var memberRole: Member.Role

        /// An alias of the ``PhenixCore/PhenixCore/Room`` or ``PhenixCore/PhenixCore/Channel``, from which the message came from.
        ///
        /// - warning: This value does not come from the original message, it is added manually when the message is received.
        var alias: String?

        init(
            message: String,
            date: Date,
            id: String,
            mimeType: String,
            memberID: String,
            memberName: String,
            memberRole: Member.Role
        ) {
            self.id = id
            self.date = date
            self.message = message
            self.mimeType = mimeType
            self.memberID = memberID
            self.memberName = memberName
            self.memberRole = memberRole
        }

        init?(_ message: PhenixChatMessage) {
            guard let author = message.getObservableFrom().getValueOrDefault() else {
                return nil
            }

            guard let authorName = author.getObservableScreenName().getValueOrDefault() as String? else {
                return nil
            }

            guard let role = Member.Role(author.getObservableMemberRole().getValueOrDefault()) else {
                return nil
            }

            guard let text = message.getObservableMessage().getValueOrDefault() as String? else {
                return nil
            }

            guard let date = message.getObservableTimeStamp().getValueOrDefault() as Date? else {
                return nil
            }

            guard let mimeType = message.getObservableMimeType().getValueOrDefault() as String? else {
                return nil
            }

            self.id = message.getId()
            self.date = date
            self.message = text
            self.mimeType = mimeType
            self.memberID = author.getSessionId()
            self.memberName = authorName
            self.memberRole = role
        }
    }
}

// MARK: - Equatable
extension PhenixCore.Message: Equatable {
    public static func == (lhs: PhenixCore.Message, rhs: PhenixCore.Message) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension PhenixCore.Message: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - CustomStringConvertible
extension PhenixCore.Message: CustomDebugStringConvertible {
    public var debugDescription: String {
        "Message(memberID: \(memberID), date: \(date), mimeType: \(mimeType), message: \(message)"
    }
}
