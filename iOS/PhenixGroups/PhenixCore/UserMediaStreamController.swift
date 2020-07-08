//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import PhenixSdk

public class UserMediaStreamController {
    private var renderer: PhenixRenderer?

    public private(set) lazy var cameraLayer: VideoLayer = {
        let layer = VideoLayer()
        renderer = makeRenderer()
        renderer?.start(layer)
        return layer
    }()

    internal let userMediaStream: PhenixUserMediaStream

    public private(set) var isAudioEnabled: Bool = true
    public private(set) var isVideoEnabled: Bool = true

    init(_ userMediaStream: PhenixUserMediaStream) {
        self.userMediaStream = userMediaStream
    }

    public func setCamera(facing mode: PhenixFacingMode) {
        let options = PhenixUserMediaOptions
            .makeUserMediaOptions()
            .setCamera(facing: mode)

        userMediaStream.apply(options)
    }

    public func setAudio(enabled: Bool) {
        isAudioEnabled = enabled
        userMediaStream.mediaStream.getAudioTracks()?.forEach { $0.setEnabled(enabled) }
    }

    public func setVideo(enabled: Bool) {
        isVideoEnabled = enabled
        userMediaStream.mediaStream.getVideoTracks()?.forEach { $0.setEnabled(enabled) }
    }
}

private extension UserMediaStreamController {
    func makeRenderer() -> PhenixRenderer {
        userMediaStream.mediaStream.createRenderer()
    }
}

extension PhenixUserMediaOptions {
    static func makeUserMediaOptions() -> PhenixUserMediaOptions {
        let userMediaConstraints = PhenixUserMediaOptions()

        userMediaConstraints.video.enabled = true
        userMediaConstraints.video.capabilityConstraints[PhenixDeviceCapability.facingMode.rawValue] = [PhenixDeviceConstraint.initWith(.user)]
        userMediaConstraints.video.capabilityConstraints[PhenixDeviceCapability.height.rawValue] = [PhenixDeviceConstraint.initWith(360)]
        userMediaConstraints.video.capabilityConstraints[PhenixDeviceCapability.frameRate.rawValue] = [PhenixDeviceConstraint.initWith(15)]

        userMediaConstraints.audio.enabled = true
        userMediaConstraints.audio.capabilityConstraints[PhenixDeviceCapability.audioEchoCancelationMode.rawValue] = [PhenixDeviceConstraint.initWith(.on)]

        return userMediaConstraints
    }

    func setCamera(facing mode: PhenixFacingMode) -> PhenixUserMediaOptions {
        video.capabilityConstraints[PhenixDeviceCapability.facingMode.rawValue] = [PhenixDeviceConstraint.initWith(mode)]
        return self
    }
}
