//
//  Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

public class RoomMember {
    public enum SubscriptionType: CustomStringConvertible {
        case audio
        case video

        public var description: String {
            switch self {
            case .audio:
                return "Audio"
            case .video:
                return "Video"
            }
        }
    }

    private weak var phenixRoomExpress: PhenixRoomExpress?
    private var disposables = [PhenixDisposable]()
    private var subscriber: PhenixExpressSubscriber?
    private var stream: PhenixStream?
    private var identifier: String {
        guard let id = phenixMember.getSessionId() else {
            fatalError("Session ID must always be available")
        }
        return id
    }

    internal let phenixMember: PhenixMember

    public private(set) var previewLayer: CALayer?
    public private(set) var subscriptionType: SubscriptionType?
    public weak var delegate: RoomMemberDelegate?
    public let isSelf: Bool
    public let screenName: String
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
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
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

        let options: PhenixSubscribeToMemberStreamOptions = {
            switch type {
            case .audio:
                previewLayer = nil
                return Self.audioOptions()

            case .video:
                let layer = CALayer()
                previewLayer = layer
                return Self.videoOptions(with: layer)
            }
        }()

        phenixRoomExpress?.subscribe(toMemberStream: stream, options) { [weak self] status, subscriber, _ in
            guard let self = self else { return }
            if status == .ok {
                self.subscriber = subscriber
                stream.getObservableAudioState()?.subscribe(self.audioStateDidChange)?.append(to: &self.disposables)
                if type == .video {
                    stream.getObservableVideoState()?.subscribe(self.videoStateDidChange)?.append(to: &self.disposables)
                }

                os_log(.debug, log: .roomMember, "Member (%{PRIVATE}s) successfully subscribed with %{PRIVATE}s", self.description, type.description)
            } else {
                os_log(.debug, log: .roomMember, "Member (%{PRIVATE}s) failed to subscribe with %{PRIVATE}s", self.description, type.description)
                self.isSubscribed = false
            }
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
        if lhs.isSelf {
            // In cases, when we need to order member lists, member object, who is Self needs to be first one.
            return true
        }

        guard let lhsLastUpdate = lhs.phenixMember.getObservableLastUpdate()?.getValue() as Date? else {
            return false
        }

        guard let rhsLastUpdate = rhs.phenixMember.getObservableLastUpdate()?.getValue() as Date? else {
            return false
        }

        return lhsLastUpdate < rhsLastUpdate
    }
}

// MARK: - Private methods
private extension RoomMember {
    func memberStreamDidChange(_ changes: PhenixObservableChange<NSArray>?) {
        guard let streams = changes?.value as? [PhenixStream] else {
            return
        }

        guard let stream = streams.first else {
            return
        }

        self.stream = stream
    }

    func audioStateDidChange(_ changes: PhenixObservableChange<NSNumber>?) {
        guard let value = changes?.value else {
            return
        }

        guard let state = PhenixTrackState(rawValue: Int(truncating: value)) else {
            return
        }

        isAudioAvailable = state == .enabled
    }

    func videoStateDidChange(_ changes: PhenixObservableChange<NSNumber>?) {
        guard let value = changes?.value else {
            return
        }

        guard let state = PhenixTrackState(rawValue: Int(truncating: value)) else {
            return
        }

        isVideoAvailable = state == .enabled
    }
}

// MARK: - Helper methods
fileprivate extension RoomMember {
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
