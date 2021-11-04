//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixSdk

public class RoomMediaController {
    private let publisher: PhenixExpressPublisher
    private let queue: DispatchQueue

    internal weak var roomRepresentation: RoomRepresentation?

    init(publisher: PhenixExpressPublisher, queue: DispatchQueue = .main) {
        self.queue = queue
        self.publisher = publisher
    }

    /// Change publishing audio state in the current room
    ///
    /// This will enabled or disable the audio publishing of the local device
    /// - Parameter enabled: True means that audio will be unmuted, false - muted
    public func setAudio(enabled: Bool) {
        queue.async { [weak self] in
            guard let self = self else { return }
            os_log(
                .debug,
                log: .mediaController,
                "%{private}s, Set audio publishing %{public}s",
                self.roomDescription,
                enabled == true ? "enabled" : "disabled"
            )
            if enabled {
                self.publisher.enableAudio()
            } else {
                self.publisher.disableAudio()
            }
        }
    }

    /// Change publishing video state in the current room
    ///
    /// This will enabled or disable the video publishing of the local device
    /// - Parameter enabled: True means that video will be enabled, false - disabled
    public func setVideo(enabled: Bool) {
        queue.async { [weak self] in
            guard let self = self else { return }
            os_log(
                .debug,
                log: .mediaController,
                "%{private}s, Set video publishing %{public}s",
                self.roomDescription,
                enabled == true ? "enabled" : "disabled"
            )
            if enabled {
                self.publisher.enableVideo()
            } else {
                self.publisher.disableVideo()
            }
        }
    }
}

// MARK: - Internal methods
internal extension RoomMediaController {
    func stop() {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(.debug, log: .mediaController, "%{private}s, Stop media", roomDescription)
        publisher.stop()
    }
}

// MARK: - Private methods
private extension RoomMediaController {
    var roomDescription: String { roomRepresentation?.alias ?? "-" }
}
