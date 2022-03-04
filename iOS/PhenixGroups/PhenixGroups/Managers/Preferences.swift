//
//  Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Combine
import Foundation
import PhenixCore
import UIKit

/// Class saves and retrieves values from device memory
/// 
/// Preferences are **not thread safe**.
class Preferences {
    private let userDefaults: UserDefaults

    private lazy var meetingsSubject: CurrentValueSubject<[Meeting], Never> = {
        guard let data = userDefaults.data(forKey: .meetings) else {
            return CurrentValueSubject<[Meeting], Never>([])
        }

        guard let result: [Meeting] = try? data.decode() else {
            return CurrentValueSubject<[Meeting], Never>([])
        }

        return CurrentValueSubject<[Meeting], Never>(result)
    }()

    var displayName: String {
        get { userDefaults.string(forKey: .displayName) ?? "Unknown" }
        set { userDefaults.set(newValue, forKey: .displayName) }
    }

    var meetings: [Meeting] {
        get { meetingsSubject.value }
        set {
            userDefaults.set(try? newValue.encode(), forKey: .meetings)
            meetingsSubject.send(newValue)
        }
    }

    private(set) lazy var meetingsPublisher = meetingsSubject.eraseToAnyPublisher()

    var currentMeetingCode: String?

    var isCameraEnabled = true
    var isMicrophoneEnabled = true

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.registerDefaults()
    }

    private func registerDefaults() {
        userDefaults.register(defaults: [
            .displayName: UIDevice.current.name
        ])
    }
}

fileprivate extension String {
    static let displayName: String = "preferences.displayName"
    static let meetings: String = "preferences.meetings"
}
