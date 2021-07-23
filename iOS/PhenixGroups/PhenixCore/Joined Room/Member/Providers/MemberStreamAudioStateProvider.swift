//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

class MemberStreamAudioStateProvider: RoomMemberDescription {
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
                log: .roomMemberStreamAudioStateProvider,
                "%{private}s, Observe audio state changes",
                self.memberDescription
            )

            self.stream
                .getObservableAudioState()
                .subscribe(self.audioStateDidChange)
                .append(to: &self.disposables)
        }
    }

    func dispose() {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(.debug, log: .roomMemberStreamAudioStateProvider, "%{private}s, Dispose", memberDescription)

        disposables.removeAll()
        stateChangeHandler = nil
    }
}

// MARK: - Observable callbacks
private extension MemberStreamAudioStateProvider {
    func audioStateDidChange(_ changes: PhenixObservableChange<NSNumber>?) {
        queue.async { [weak self] in
            guard let value = changes?.value else { return }
            guard let state = PhenixTrackState(rawValue: Int(truncating: value)) else { return }

            self?.stateChangeHandler?(state == .enabled)
        }
    }
}
