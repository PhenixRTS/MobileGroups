//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

class MemberStreamVideoStateProvider: RoomMemberDescription {
    private let queue: DispatchQueue
    private let stream: PhenixStream
    private var disposables: [PhenixDisposable]

    internal weak var memberRepresentation: RoomMemberRepresentation?
    internal var stateChangeHandler: ((Bool) -> Void)?

    init(stream: PhenixStream, queue: DispatchQueue) {
        self.queue = queue
        self.stream = stream
        self.disposables = []
    }

    func observeState() {
        queue.async { [weak self] in
            guard let self = self else { return }

            os_log(
                .debug,
                log: .roomMemberStreamVideoStateProvider,
                "%{private}s, Observe video state changes",
                self.memberDescription
            )

            self.stream
                .getObservableVideoState()
                .subscribe(self.videoStateDidChange)
                .append(to: &self.disposables)
        }
    }

    func dispose() {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(
            .debug,
            log: .roomMemberStreamVideoStateProvider,
            "%{private}s, Dispose",
            self.memberDescription
        )

        disposables.removeAll()
        stateChangeHandler = nil
    }
}

// MARK: - Observable callbacks
private extension MemberStreamVideoStateProvider {
    func videoStateDidChange(_ changes: PhenixObservableChange<NSNumber>?) {
        queue.async { [weak self] in
            guard let value = changes?.value else { return }
            guard let state = PhenixTrackState(rawValue: Int(truncating: value)) else { return }

            self?.stateChangeHandler?(state == .enabled)
        }
    }
}
