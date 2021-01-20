//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

/// Class saves and retrieves values from device memory
/// 
/// Preferences are **not thread safe**.
class Preferences {
    private let userDefaults: UserDefaults

    var displayName: String? {
        get { userDefaults.string(forKey: .displayName) }
        set { userDefaults.set(newValue, forKey: .displayName) }
    }

    var meetings: [Meeting] {
        get {
            if let data = userDefaults.data(forKey: .meetings) {
                if let result: [Meeting] = try? data.decode() {
                    return result
                }
            }
            return []
        }
        set { userDefaults.set(try? newValue.encode(), forKey: .meetings) }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
}

fileprivate extension String {
    static let displayName: String = "com.phenixrts.suite.groups.preferences.displayName"
    static let meetings: String = "com.phenixrts.suite.groups.preferences.meetings"
}
