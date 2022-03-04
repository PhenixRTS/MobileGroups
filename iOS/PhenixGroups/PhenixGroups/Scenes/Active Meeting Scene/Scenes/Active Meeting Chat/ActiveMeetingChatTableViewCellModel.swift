//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Combine
import Foundation

extension ActiveMeetingChatTableViewCell {
    class ViewModel {
        private static let formatter: RelativeDateTimeFormatter = {
            let formatter = RelativeDateTimeFormatter()
            formatter.dateTimeStyle = .named
            formatter.formattingContext = .listItem
            return formatter
        }()

        var author: String
        var text: String
        var date: Date
        var localizedDate: String { localizeRelativeDateTime(date) }

        private(set) lazy var localizedDatePublisher: AnyPublisher<String, Never> = {
            Timer.publish(every: 1, tolerance: 0.2, on: RunLoop.main, in: .common, options: nil)
                .autoconnect()
                .share()
                .map { [weak self] _ in self?.localizedDate ?? "" }
                .eraseToAnyPublisher()
        }()

        init(preferences: Preferences, message: ChatMessage) {
            // If the display name matches the author name of the message
            // mask it as "You".
            self.author = preferences.displayName == message.author ? "You" : message.author
            self.text = message.text
            self.date = message.date
        }

        private func localizeRelativeDateTime(_ date: Date) -> String {
            let now = Date()
            if now.timeIntervalSince(date) > 60 {
                return Self.formatter.localizedString(for: date, relativeTo: now)
            } else {
                return "Now"
            }
        }
    }
}
