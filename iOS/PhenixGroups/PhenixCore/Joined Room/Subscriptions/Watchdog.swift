//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation

class Watchdog {
    private let timeInterval: TimeInterval
    private let workItem: DispatchWorkItem
    private let queue: DispatchQueue

    init(timeInterval: TimeInterval, queue: DispatchQueue = .main, afterTimePasses: @escaping () -> Void) {
        self.queue = queue
        self.timeInterval = timeInterval
        workItem = DispatchWorkItem(block: afterTimePasses)
    }
    func start() {
        queue.asyncAfter(deadline: .now() + timeInterval, execute: workItem)
    }

    func cancel() {
        workItem.cancel()
    }

    deinit {
        cancel()
    }
}
