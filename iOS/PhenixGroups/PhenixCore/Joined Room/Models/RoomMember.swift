//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

public class RoomMember {
    public enum SubscriptionType {
        case audio
        case video
    }

    private weak var phenixRoomExpress: PhenixRoomExpress?
    private var disposables = [PhenixDisposable]()
    private var subscriber: PhenixExpressSubscriber?
    private var stream: PhenixStream?
    internal var identifier: String {
        guard let id = phenixMember.getSessionId() else {
            fatalError("Session ID must always be available")
        }
        return id
    }

    internal let phenixMember: PhenixMember

    public private(set) var subscriptionType: SubscriptionType?
    public var previewLayer: VideoLayer?
    public let isSelf: Bool
    public let screenName: String
    public weak var delegate: RoomMemberDelegate?
    public var isSubscribed: Bool = false
    public var isAudioAvailable = false {
        didSet {
            delegate?.roomMemberAudioStateDidChange(self, enabled: isAudioAvailable)
        }
    }
    public var isVideoAvailable = false {
        didSet {
            delegate?.roomMemberVideoStateDidChange(self, enabled: isVideoAvailable)
        }
    }

    internal init(_ member: PhenixMember, isSelf: Bool, roomExpress: PhenixRoomExpress) {
        self.phenixMember = member
        self.isSelf = isSelf
        self.phenixRoomExpress = roomExpress
        self.screenName = (member.getObservableScreenName()?.getValue() ?? "N/A") as String
    }

    internal func observe() {
        phenixMember.getObservableStreams()?.subscribe(memberStreamDidChange)?.append(to: &disposables)
    }

    internal func dispose() {
        disposables.removeAll()
        subscriber?.stop()
        DispatchQueue.main.async { [weak self] in
            self?.previewLayer?.removeFromSuperlayer()
            self?.previewLayer = nil
        }
    }

    public func subscribe(for type: SubscriptionType) {
        guard let stream = stream else {
            os_log(.debug, log: .roomMember, "Member (%{PRIVATE}s) does not contain stream", self.description)
            return
        }

        guard isSubscribed == false else {
            os_log(.debug, log: .roomMember, "Member (%{PRIVATE}s) is already subscribed", self.description)
            return
        }

        guard isSelf == false else {
            os_log(.debug, log: .roomMember, "Member (%{PRIVATE}s) is Self", self.description)
            return
        }

        isSubscribed = true
        subscriptionType = type

        let preferences = makeStreamOptions(for: type)
        previewLayer = preferences.layer

        phenixRoomExpress?.subscribe(toMemberStream: stream, preferences.options) { [weak self] status, subscriber, _ in
            guard let self = self else { return }
            if status == .ok {
                self.subscriber = subscriber
                stream.getObservableAudioState()?.subscribe(self.audioStateDidChange)?.append(to: &self.disposables)
                stream.getObservableVideoState()?.subscribe(self.videoStateDidChange)?.append(to: &self.disposables)

                os_log(.debug, log: .roomMember, "Member (%{PRIVATE}s) successfully subscribed with %{PRIVATE}s", self.description, String(describing: type))
            } else {
                os_log(.debug, log: .roomMember, "Member (%{PRIVATE}s) failed to subscribe with %{PRIVATE}s", self.description, String(describing: type))
                self.isSubscribed = false
            }
        }
    }
}

internal extension RoomMember {
    func makeStreamOptions(for type: SubscriptionType) -> (layer: VideoLayer?, options: PhenixSubscribeToMemberStreamOptions) {
        switch type {
        case .audio:
            return (layer: nil, options: Self.audioOptions())

        case .video:
            let layer = VideoLayer()
            return (layer: layer, options: Self.videoOptions(with: layer))
        }
    }
}

// MARK: - CustomStringConvertible
extension RoomMember: CustomStringConvertible {
    public var description: String {
        "RoomMember, session identifier: \(identifier) name: \(screenName), isSelf: \(isSelf), audio: \(isAudioAvailable), video: \(isVideoAvailable)"
    }
}

// MARK: - Hashable
extension RoomMember: Hashable {
    public static func == (lhs: RoomMember, rhs: RoomMember) -> Bool {
        lhs.identifier == rhs.identifier
    }

    public static func == (lhs: RoomMember, rhs: PhenixMember) -> Bool {
        lhs.identifier == rhs.getSessionId()
    }

    public static func == (lhs: PhenixMember, rhs: RoomMember) -> Bool {
        lhs.getSessionId() == rhs.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

// MARK: - Comparable
extension RoomMember: Comparable {
    public static func < (lhs: RoomMember, rhs: RoomMember) -> Bool {
        guard let lhsLastUpdate = lhs.phenixMember.getObservableLastUpdate()?.getValue() as Date? else {
            return true
        }

        guard let rhsLastUpdate = rhs.phenixMember.getObservableLastUpdate()?.getValue() as Date? else {
            return false
        }

        return lhsLastUpdate < rhsLastUpdate
    }
}

// MARK: - Observable callback methods
private extension RoomMember {
    func memberStreamDidChange(_ changes: PhenixObservableChange<NSArray>?) {
        guard let streams = changes?.value as? [PhenixStream] else { return }
        guard let stream = streams.first else { return }

        self.stream = stream
    }

    func audioStateDidChange(_ changes: PhenixObservableChange<NSNumber>?) {
        guard let value = changes?.value else { return }
        guard let state = PhenixTrackState(rawValue: Int(truncating: value)) else { return }

        isAudioAvailable = state == .enabled
    }

    func videoStateDidChange(_ changes: PhenixObservableChange<NSNumber>?) {
        guard let value = changes?.value else { return }
        guard let state = PhenixTrackState(rawValue: Int(truncating: value)) else { return }

        isVideoAvailable = state == .enabled
    }
}

// MARK: - Helper methods
private extension RoomMember {
    static func videoOptions(with layer: CALayer) -> PhenixSubscribeToMemberStreamOptions {
        PhenixRoomExpressFactory.createSubscribeToMemberStreamOptionsBuilder()
            .withRenderer(layer)
            .buildSubscribeToMemberStreamOptions()
    }

    static func audioOptions() -> PhenixSubscribeToMemberStreamOptions {
        PhenixRoomExpressFactory.createSubscribeToMemberStreamOptionsBuilder()
            .withCapabilities(["audio-only"])
            .withAudioOnlyRenderer()
            .buildSubscribeToMemberStreamOptions()
    }
}
