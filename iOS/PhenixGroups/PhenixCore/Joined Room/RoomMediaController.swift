//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixSdk

public class RoomMediaController {
    private let publisher: PhenixExpressPublisher
    private let queue: DispatchQueue

    internal weak var roomRepresentation: RoomRepresentation?

    init(publisher: PhenixExpressPublisher, queue: DispatchQueue = .main, roomRepresentation: RoomRepresentation? = nil) {
        self.queue = queue
        self.publisher = publisher
        self.roomRepresentation = roomRepresentation
    }

    /// Change room audio state
    /// - Parameter enabled: True means that audio will be unmuted, false - muted
    public func setAudio(enabled: Bool) {
        queue.async { [weak self] in
            guard let self = self else { return }
            os_log(.debug, log: .mediaController, "Set audio %{PUBLIC}s, (%{PRIVATE}s)", enabled == true ? "enabled" : "disabled", self.roomDescription)
            if enabled {
                self.publisher.enableAudio()
            } else {
                self.publisher.disableAudio()
            }
        }
    }

    /// Change room video state
    /// - Parameter enabled: True means that video will be enabled, false - disabled
    public func setVideo(enabled: Bool) {
        queue.async { [weak self] in
            guard let self = self else { return }
            os_log(.debug, log: .mediaController, "Set video %{PUBLIC}s, (%{PRIVATE}s)", enabled == true ? "enabled" : "disabled", self.roomDescription)
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

        os_log(.debug, log: .mediaController, "Stop media, (%{PRIVATE}s)", roomDescription)
        publisher.stop()
    }
}

// MARK: - Private methods
private extension RoomMediaController {
    var roomDescription: String { roomRepresentation?.alias ?? "-" }
}
