//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import os.log
import PhenixSdk

internal protocol RoomMemberMediaDelegate: AnyObject {
    func audioStateDidChange(enabled: Bool)
    func videoStateDidChange(enabled: Bool)
    func audioLevelDidChange(decibel: Double)
}

public class RoomMemberMediaController {
    private weak var renderer: PhenixRenderer?

    private let stream: PhenixStream
    private let queue: DispatchQueue
    private let audioTracks: [PhenixMediaStreamTrack]?
    private let audioLevelQueue: DispatchQueue
    private let audioLevelProvider: AudioLevelProvider
    private var mediaDisposables: [PhenixDisposable]
    private var audioLevelCache: [Double]

    internal weak var delegate: RoomMemberMediaDelegate?
    internal weak var memberRepresentation: RoomMemberRepresentation?

    public private(set) var isAudioAvailable = false {
        didSet {
            os_log(.debug, log: .roomMemberMediaController, "Audio state changed, (%{PRIVATE}s), (%{PRIVATE}s)", self.description, self.memberDescription)
            delegate?.audioStateDidChange(enabled: isAudioAvailable)
        }
    }
    public private(set) var isVideoAvailable = false {
        didSet {
            os_log(.debug, log: .roomMemberMediaController, "Video state changed, (%{PRIVATE}s), (%{PRIVATE}s)", self.description, self.memberDescription)
            delegate?.videoStateDidChange(enabled: isVideoAvailable)
        }
    }

    init(
        stream: PhenixStream,
        renderer: PhenixRenderer?,
        audioTracks: [PhenixMediaStreamTrack]?,
        queue: DispatchQueue = .main
    ) {
        self.queue = queue
        self.stream = stream
        self.renderer = renderer
        self.audioTracks = audioTracks
        self.audioLevelQueue = DispatchQueue(
            label: "com.phenixrts.suite.groups.core.RoomMemberMediaController.AudioLevelProvider",
            qos: .userInitiated,
            attributes: .concurrent,
            target: queue
        )
        self.audioLevelProvider = AudioLevelProvider(queue: queue)
        self.mediaDisposables = []
        self.audioLevelCache = []

        self.audioLevelProvider.audioProcessCompletion = { [weak self] decibel in
            self?.processAudioLevel(decibel: decibel)
        }
    }

    /// Retrieves recent max audio level in range -100...0 where -100 is the lowest but the 0 is the highest
    ///
    /// Be aware that after retrieving the audio level it will purge the cache of all saved audio levels till now.
    /// - Returns: Decibels
    public func recentAudioLevel() -> Double {
        let maxDecibel = audioLevelQueue.sync {
            audioLevelCache.max() ?? AudioLevelProvider.minimumDecibel
        }

        audioLevelQueue.async(flags: [.barrier]) { [weak self] in
            self?.audioLevelCache.removeAll()
        }

        return maxDecibel
    }
}

// MARK: - CustomStringConvertible
extension RoomMemberMediaController: CustomStringConvertible {
    public var description: String {
        "RoomMemberMediaController, audio: \(isAudioAvailable), video: \(isVideoAvailable)"
    }
}

// MARK: - Internal methods
internal extension RoomMemberMediaController {
    func observeAudioStream() {
        queue.async { [weak self] in
            guard let self = self else { return }

            os_log(.debug, log: .roomMemberMediaController, "Observe audio state changes, (%{PRIVATE}s)", self.memberDescription)
            self.stream
                .getObservableAudioState()
                .subscribe(self.audioStateDidChange)
                .append(to: &self.mediaDisposables)
        }
    }

    func observeVideoStream() {
        queue.async { [weak self] in
            guard let self = self else { return }

            os_log(.debug, log: .roomMemberMediaController, "Observe video state changes, (%{PRIVATE}s)", self.memberDescription)
            self.stream
                .getObservableVideoState()
                .subscribe(self.videoStateDidChange)
                .append(to: &self.mediaDisposables)
        }
    }

    func observeAudioLevel() {
        queue.async { [weak self] in
            guard let self = self else { return }

            guard let renderer = self.renderer else {
                os_log(.error, log: .roomMemberMediaController, "%{PRIVATE}s, renderer not provided, (%{PRIVATE}s)", #function, self.memberDescription)
                return
            }
            guard let track = self.audioTracks?.first else { return }

            os_log(.debug, log: .roomMemberMediaController, "Observe audio level changes, (%{PRIVATE}s)", self.memberDescription)
            renderer.setFrameReadyCallback(track, self.didReceiveAudioFrame)
        }
    }

    func processAudioLevel(decibel: Double) {
        queue.async { [weak self] in
            self?.audioLevelQueue.async(flags: [.barrier]) {
                self?.audioLevelCache.append(decibel)
            }
            self?.delegate?.audioLevelDidChange(decibel: decibel)
        }
    }

    func dispose() {
        dispatchPrecondition(condition: .onQueue(queue))

        os_log(.debug, log: .roomMemberMediaController, "Dispose, (%{PRIVATE}s), (%{PRIVATE}s)", self.description, self.memberDescription)
        self.mediaDisposables.removeAll()

        if let track = self.audioTracks?.first {
            self.renderer?.setFrameReadyCallback(track, nil)
        }
    }
}

// MARK: - Private methods
private extension RoomMemberMediaController {
    var memberDescription: String { memberRepresentation?.identifier ?? "-" }
}

// MARK: - Observable callbacks
private extension RoomMemberMediaController {
    func audioStateDidChange(_ changes: PhenixObservableChange<NSNumber>?) {
        queue.async { [weak self] in
            guard let value = changes?.value else { return }
            guard let state = PhenixTrackState(rawValue: Int(truncating: value)) else { return }

            self?.isAudioAvailable = state == .enabled
        }
    }

    func videoStateDidChange(_ changes: PhenixObservableChange<NSNumber>?) {
        queue.async { [weak self] in
            guard let value = changes?.value else { return }
            guard let state = PhenixTrackState(rawValue: Int(truncating: value)) else { return }

            self?.isVideoAvailable = state == .enabled
        }
    }

    func didReceiveAudioFrame(_ notification: PhenixFrameNotification?) {
        notification?.read { [weak self] sampleBuffer in
            guard let sampleBuffer = sampleBuffer else { return }
            self?.audioLevelProvider.process(sampleBuffer)
        }
    }
}
