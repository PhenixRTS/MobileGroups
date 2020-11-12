//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixSdk

public struct PhenixRoomChatMessage {
    public var id: String
    public var authorId: String
    public var authorName: String
    public var text: String
    public var date: Date

    init?(_ message: PhenixChatMessage) {
        guard let author = message.getObservableFrom()?.getValue() else { return nil }
        guard let authorName = message.getObservableFrom()?.getValue()?.getObservableScreenName()?.getValue() as String? else { return nil }
        guard let text = message.getObservableMessage()?.getValue() as String? else { return nil }
        guard let date = message.getObservableTimeStamp()?.getValue() as Date? else { return nil }

        self.id = message.getId()
        self.authorId = author.getSessionId()
        self.authorName = authorName
        self.text = text
        self.date = date
    }

    public mutating func maskAsYourself() {
        authorName = "You"
    }
}
