//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

extension ActiveMeetingInformationViewController {
    class ViewModel {
        private let session: AppSession
        private let preferences: Preferences

        var meetingCode: String {
            if let code = preferences.currentMeetingCode {
                return code
            } else {
                fatalError("Meeting code not provided.")
            }
        }

        private(set) lazy var sharableUrl: URL = {
            var components = URLComponents()
            components.scheme = "https"
            components.host = "phenixrts.com"
            components.path = "/group/"
            components.fragment = preferences.currentMeetingCode
            components.queryItems = [
                URLQueryItem(name: "authToken", value: session.authToken),
                URLQueryItem(name: "publishToken", value: session.publishToken),
                URLQueryItem(name: "roomAudioToken", value: session.audioStreamToken),
                URLQueryItem(name: "roomVideoToken", value: session.videoStreamToken)
            ]
            return components.url! // swiftlint:disable:this force_unwrapping
        }()

        private(set) lazy var sharableText: String = {
            sharableUrl.absoluteString
        }()

        init(session: AppSession, preferences: Preferences) {
            self.session = session
            self.preferences = preferences
        }
    }
}
