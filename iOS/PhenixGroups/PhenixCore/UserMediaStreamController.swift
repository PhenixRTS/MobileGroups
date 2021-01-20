//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import PhenixSdk

internal protocol UserMediaProvider: AnyObject {
    var renderer: PhenixRenderer? { get }
    var audioTracks: [PhenixMediaStreamTrack] { get }
}

public class UserMediaStreamController {
    public typealias AudioFrameNotificationHandler = () -> Void
    public typealias VideoFrameNotificationHandler = () -> Void

    internal private(set) var renderer: PhenixRenderer? {
        didSet { subscribeForMediaFrameNotification() }
    }

    internal let userMediaStream: PhenixUserMediaStream
    internal var cameraMode: PhenixFacingMode = .user {
        didSet { setCamera(facing: cameraMode) }
    }

    public private(set) lazy var cameraLayer: VideoLayer = {
        let layer = VideoLayer()
        renderer = makeRenderer()
        renderer?.start(layer)
        return layer
    }()

    /// Indicates current device audio state
    public private(set) var isAudioEnabled: Bool = true
    /// Indicates current device video state
    public private(set) var isVideoEnabled: Bool = true

    /// Handler for audio frame notifications
    public var audioFrameReadHandler: AudioFrameNotificationHandler?
    /// Handler for video frame notifications
    public var videoFrameReadHandler: VideoFrameNotificationHandler?

    init(_ userMediaStream: PhenixUserMediaStream) {
        self.userMediaStream = userMediaStream
    }

    public func setAudio(enabled: Bool) {
        isAudioEnabled = enabled
        userMediaStream.mediaStream.getAudioTracks()?.forEach { $0.setEnabled(enabled) }
    }

    public func setVideo(enabled: Bool) {
        isVideoEnabled = enabled
        userMediaStream.mediaStream.getVideoTracks()?.forEach { $0.setEnabled(enabled) }
    }

    public func switchCamera() {
        cameraMode = cameraMode == .user ? .environment : .user
    }
}

// MARK: - Private methods
private extension UserMediaStreamController {
    func makeRenderer() -> PhenixRenderer {
        userMediaStream.mediaStream.createRenderer()
    }

    func setCamera(facing mode: PhenixFacingMode) {
        let options = PhenixUserMediaOptions
            .makeUserMediaOptions()
            .setCamera(facing: mode)

        userMediaStream.apply(options)
    }

    func subscribeForMediaFrameNotification() {
        guard let renderer = renderer else {
            return
        }

        // Get the current device audio track.
        if let audioTrack = userMediaStream.mediaStream.getAudioTracks()?.first {
            renderer.setFrameReadyCallback(audioTrack, audioFrameNotificationReceived)
        }

        // Get the current device video track.
        if let videoTrack = userMediaStream.mediaStream.getVideoTracks()?.first {
            renderer.setFrameReadyCallback(videoTrack, videoFrameNotificationReceived)
        }
    }

    func audioFrameNotificationReceived(_ notification: PhenixFrameNotification?) {
        audioFrameReadHandler?()
    }

    func videoFrameNotificationReceived(_ notification: PhenixFrameNotification?) {
        videoFrameReadHandler?()
    }
}

// MARK: - UserMediaProvider
extension UserMediaStreamController: UserMediaProvider {
    var audioTracks: [PhenixMediaStreamTrack] {
        userMediaStream.mediaStream.getAudioTracks()
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
