//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixDeeplink

struct PhenixDeeplinkModel: PhenixDeeplinkModelProvider {
    var alias: String?
    var uri: URL?
    var backend: URL?
    var maxVideoMembers: Int?

    init?(components: URLComponents) {
        self.alias = components.fragment

        if let string = components.queryItems?.first(where: { $0.name == "uri" })?.value {
            self.uri = URL(string: string)
        }

        if let string = components.queryItems?.first(where: { $0.name == "backend" })?.value {
            self.backend = URL(string: string)
        }

        if let string = components.queryItems?.first(where: { $0.name == "maxVideoMembers" })?.value {
            self.maxVideoMembers = Int(string)
        }
    }
}
