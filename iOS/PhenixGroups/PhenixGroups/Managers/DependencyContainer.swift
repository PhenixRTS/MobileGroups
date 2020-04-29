//
// Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import PhenixCore

class DependencyContainer {
    let phenixManager: PhenixManager
    let preferences: Preferences

    init(phenixManager: PhenixManager, preferences: Preferences) {
        self.phenixManager = phenixManager
        self.preferences = preferences
    }
}
