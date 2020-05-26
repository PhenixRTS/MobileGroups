//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import PhenixSdk
import UIKit

public class UserMediaStreamController {
    internal let userMediaStream: PhenixUserMediaStream

    private var cameraLayer: CALayer!
    private var renderer: PhenixRenderer?

    init(_ userMediaStream: PhenixUserMediaStream) {
        self.userMediaStream = userMediaStream
    }

    public func setPreview(on view: UIView) {
        if renderer == nil {
            renderer = makeRenderer()
        }

        if let cameraLayer = cameraLayer {
            if view.layer != cameraLayer.superlayer {
                view.layer.add(cameraLayer)
            }
        } else {
            cameraLayer = CALayer()
            view.layer.add(cameraLayer)
            renderer?.start(cameraLayer)
        }
    }

    public func setCamera(facing mode: PhenixFacingMode) {
        let options = PhenixUserMediaOptions
            .makeUserMediaOptions()
            .setCamera(facing: mode)

        userMediaStream.apply(options)
    }

    public func setVideoEnabled(_ enabled: Bool) {
        userMediaStream.mediaStream.getVideoTracks()?.first?.setEnabled(enabled)
    }

    public func setAudioEnabled(_ enabled: Bool) {
        userMediaStream.mediaStream.getAudioTracks()?.first?.setEnabled(enabled)
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
        userMediaConstraints.video.capabilityConstraints[PhenixDeviceCapability.height.rawValue]     = [PhenixDeviceConstraint.initWith(360)]
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

fileprivate extension CALayer {
    func resize(as otherLayer: CALayer) {
        frame = otherLayer.bounds
    }

    func add(_ layer: CALayer) {
        layer.resize(as: self)
        addSublayer(layer)
    }
}
