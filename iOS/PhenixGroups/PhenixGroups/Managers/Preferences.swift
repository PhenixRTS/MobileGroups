//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

class Preferences {
    private let userDefaults: UserDefaults

    var displayName: String? {
        get { userDefaults.string(forKey: .displayName) }
        set { userDefaults.set(newValue, forKey: .displayName) }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
}

fileprivate extension String {
    static let displayName: String = "com.phenixrts.suite.groups.preferences.displayName"
}
