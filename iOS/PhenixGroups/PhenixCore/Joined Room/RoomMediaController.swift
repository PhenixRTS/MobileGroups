//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixSdk

public class RoomMediaController {
    private let publisher: PhenixExpressPublisher

    internal weak var roomRepresentation: RoomRepresentation?

    init(publisher: PhenixExpressPublisher, roomRepresentation: RoomRepresentation? = nil) {
        self.publisher = publisher
        self.roomRepresentation = roomRepresentation
    }

    /// Change room audio state
    /// - Parameter enabled: True means that audio will be unmuted, false - muted
    public func setAudio(enabled: Bool) {
        if enabled {
            os_log(.debug, log: .mediaController, "Enable audio, (%{PRIVATE}s)", roomDescription)
            publisher.enableAudio()
        } else {
            os_log(.debug, log: .mediaController, "Disable audio, (%{PRIVATE}s)", roomDescription)
            publisher.disableAudio()
        }
    }

    /// Change room video state
    /// - Parameter enabled: True means that video will be enabled, false - disabled
    public func setVideo(enabled: Bool) {
        if enabled {
            os_log(.debug, log: .mediaController, "Enable video, (%{PRIVATE}s)", roomDescription)
            publisher.enableVideo()
        } else {
            os_log(.debug, log: .mediaController, "Disable video, (%{PRIVATE}s)", roomDescription)
            publisher.disableVideo()
        }
    }
}

// MARK: - Internal methods
internal extension RoomMediaController {
    func stop() {
        os_log(.debug, log: .mediaController, "Stop media, (%{PRIVATE}s)", roomDescription)
        publisher.stop()
    }
}

// MARK: - Private methods
private extension RoomMediaController {
    var roomDescription: String { roomRepresentation?.alias ?? "-" }
}
