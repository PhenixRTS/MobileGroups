//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

protocol RoomMemberMediaDelegate: AnyObject {
    func audioStateDidChange(enabled: Bool)
    func videoStateDidChange(enabled: Bool)
    func audioLevelDidChange(decibel: Double)
}

public protocol MediaAvailability {
    var isAudioAvailable: Bool { get }
    var isVideoAvailable: Bool { get }
}

public protocol RecentAudioLevelProvider {
    func recentAudioLevel() -> Double
}

public class RoomMemberMediaController: MediaAvailability, RecentAudioLevelProvider, RoomMemberDescription {
    private let queue: DispatchQueue
    private let audioLevelQueue: DispatchQueue
    private var audioLevelCache: [Double]

    private var videoStateProvider: MemberStreamVideoStateProvider?
    private var audioStateProvider: MemberStreamAudioStateProvider?
    private var audioLevelProvider: MemberStreamAudioLevelProvider?

    internal weak var delegate: RoomMemberMediaDelegate?
    internal weak var memberRepresentation: RoomMemberRepresentation?

    public private(set) var isAudioAvailable = false {
        didSet {
            os_log(.debug, log: .roomMemberMediaController, "Audio state changed, (%{PRIVATE}s), (%{PRIVATE}s)", memberDescription, description)
            delegate?.audioStateDidChange(enabled: isAudioAvailable)
        }
    }
    public private(set) var isVideoAvailable = false {
        didSet {
            os_log(.debug, log: .roomMemberMediaController, "Video state changed, (%{PRIVATE}s), (%{PRIVATE}s)", memberDescription, description)
            delegate?.videoStateDidChange(enabled: isVideoAvailable)
        }
    }

    init(queue: DispatchQueue = .main) {
        self.queue = queue
        self.audioLevelQueue = DispatchQueue(
            label: "com.phenixrts.suite.groups.core.RoomMemberMediaController.AudioLevelProvider",
            qos: .userInitiated,
            attributes: .concurrent,
            target: queue
        )
        self.audioLevelCache = []
    }

    /// Retrieves recent max audio level in range -100...0 where -100 is the lowest but the 0 is the highest
    ///
    /// Be aware that after retrieving the audio level it will purge the cache of all saved audio levels till now.
    /// - Returns: Decibels
    public func recentAudioLevel() -> Double {
        // Retrieve max audio decibel value and return it.
        // After we have calculated the max value, clear
        // the cache so that next time we would receive
        // new max audio level value.

        let maxDecibel = audioLevelQueue.sync {
            audioLevelCache.max() ?? MemberStreamAudioLevelProvider.minimumDecibel
        }

        audioLevelQueue.async(flags: [.barrier]) { [weak self] in
            self?.audioLevelCache.removeAll()
        }

        return maxDecibel
    }

    func setAudioLevelProvider(_ provider: MemberStreamAudioLevelProvider) {
        self.audioLevelProvider = provider

        os_log(.debug, log: .roomMemberMediaController, "Audio level provider set, (%{PRIVATE}s), (%{PRIVATE}s)", memberDescription, description)

        provider.audioProcessCompletion = { [weak self] decibel in
            self?.processAudioLevel(decibel: decibel)
        }
        provider.observeLevel()
    }

    func setAudioStateProvider(_ provider: MemberStreamAudioStateProvider) {
        self.audioStateProvider = provider

        os_log(.debug, log: .roomMemberMediaController, "Audio state provider set, (%{PRIVATE}s), (%{PRIVATE}s)", memberDescription, description)

        provider.stateChangeHandler = { [weak self] enabled in
            self?.isAudioAvailable = enabled
        }
        provider.observeState()
    }

    func setVideoStateProvider(_ provider: MemberStreamVideoStateProvider) {
        self.videoStateProvider = provider

        os_log(.debug, log: .roomMemberMediaController, "Video state provider set, (%{PRIVATE}s), (%{PRIVATE}s)", memberDescription, description)

        provider.stateChangeHandler = { [weak self] enabled in
            self?.isVideoAvailable = enabled
        }
        provider.observeState()
    }
}

// MARK: - CustomStringConvertible
extension RoomMemberMediaController: CustomStringConvertible {
    public var description: String {
        "RoomMemberMediaController(audio: \(isAudioAvailable), video: \(isVideoAvailable))"
    }
}

// MARK: - Internal methods
internal extension RoomMemberMediaController {
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

        os_log(.debug, log: .roomMemberMediaController, "Dispose, (%{PRIVATE}s), (%{PRIVATE}s)", memberDescription, description)

        videoStateProvider?.dispose()
        videoStateProvider = nil

        audioStateProvider?.dispose()
        audioStateProvider = nil

        audioLevelProvider?.dispose()
        audioLevelProvider = nil
    }
}
