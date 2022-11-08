//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixCore
import PhenixDeeplink
import UIKit

final class AppSession {
    enum ConfigurationError: Error {
        case missingMandatoryDeeplinkProperties
        case mismatch
    }

    struct Configuration {
        var maxVideoSubscriptions: Int
    }

    let authToken: String
    let publishToken: String?
    let configuration: Configuration
    let audioStreamToken: String
    let videoStreamToken: String

    var meetingCode: String?

    init(deeplink: PhenixDeeplinkModel, configuration: Configuration = .default) throws {
        guard let authToken = deeplink.authToken,
              let publishToken = deeplink.publishToken,
              let audioStreamToken = deeplink.roomAudioStreamToken,
              let videoStreamToken = deeplink.roomVideoStreamToken else {
            throw ConfigurationError.missingMandatoryDeeplinkProperties
        }

        self.authToken = authToken
        self.publishToken = publishToken
        self.configuration = configuration
        self.audioStreamToken = audioStreamToken
        self.videoStreamToken = videoStreamToken
    }

    func validate(_ deeplink: PhenixDeeplinkModel) throws {
        if let token = deeplink.authToken, token != self.authToken {
            throw ConfigurationError.mismatch
        }

        if let token = deeplink.publishToken, token != self.publishToken {
            throw ConfigurationError.mismatch
        }

        if let token = deeplink.roomAudioStreamToken, token != self.audioStreamToken {
            throw ConfigurationError.mismatch
        }

        if let token = deeplink.roomVideoStreamToken, token != self.videoStreamToken {
            throw ConfigurationError.mismatch
        }
    }
}

extension AppSession.Configuration {
    static let `default` = AppSession.Configuration(maxVideoSubscriptions: 6)
}

extension AppSession: Equatable {
    static func == (lhs: AppSession, rhs: AppSession) -> Bool {
        lhs.authToken == rhs.authToken
        && lhs.publishToken == rhs.publishToken
        && lhs.audioStreamToken == rhs.audioStreamToken
        && lhs.videoStreamToken == rhs.videoStreamToken
    }
}
