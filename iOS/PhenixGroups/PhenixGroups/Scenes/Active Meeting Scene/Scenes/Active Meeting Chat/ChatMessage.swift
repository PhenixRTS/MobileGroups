//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import PhenixCore

struct ChatMessage: Identifiable, Hashable {
    let id: String
    let author: String
    let text: String
    let date: Date

    init(_ rawMessage: PhenixCore.Message) {
        self.id = rawMessage.id
        self.author = rawMessage.memberName
        self.text = rawMessage.message
        self.date = rawMessage.date
    }
}
