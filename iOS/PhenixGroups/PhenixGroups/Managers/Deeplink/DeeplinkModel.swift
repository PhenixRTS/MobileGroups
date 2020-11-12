//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

public struct DeeplinkModel: DeeplinkModelProvider {
    var alias: String?
    var uri: URL?
    var backend: URL?

    public init?(components: URLComponents) {
        self.alias = components.fragment

        if let string = components.queryItems?.first(where: { $0.name == "uri" })?.value {
            self.uri = URL(string: string)
        }

        if let string = components.queryItems?.first(where: { $0.name == "backend" })?.value {
            self.backend = URL(string: string)
        }
    }
}
