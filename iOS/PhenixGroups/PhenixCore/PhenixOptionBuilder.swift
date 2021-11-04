//
//  Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
//

import Foundation
import os.log
import PhenixSdk

enum PhenixOptionBuilder {
    static func createPCastExpressOptions(
        backend: URL,
        pcast: URL?,
        unrecoverableErrorCallback: @escaping (_ description: String?) -> Void
    ) -> PhenixPCastExpressOptions {
        var builder: PhenixPCastExpressOptionsBuilder = PhenixPCastExpressFactory.createPCastExpressOptionsBuilder()
            .withMinimumConsoleLogLevel("Info")
            .withBackendUri(backend.absoluteString)
            .withUnrecoverableErrorCallback { _, description in
                os_log(.error, log: .phenixManager, "Unrecoverable Error: %{PRIVATE}s", String(describing: description))
                unrecoverableErrorCallback(description)
            }

        if let pcast = pcast {
            builder = builder.withPCastUri(pcast.absoluteString)
        }

        return builder.buildPCastExpressOptions()
    }

    static func createRoomExpressOptions(
        with pcastExpressOptions: PhenixPCastExpressOptions
    ) -> PhenixRoomExpressOptions {
        PhenixRoomExpressFactory.createRoomExpressOptionsBuilder()
            .withPCastExpressOptions(pcastExpressOptions)
            .buildRoomExpressOptions()
    }

    static func createRoomOptions(alias: String) -> PhenixRoomOptions {
        PhenixRoomServiceFactory.createRoomOptionsBuilder()
            .withName(alias)
            .withAlias(alias)
            .withType(.multiPartyChat)
            .buildRoomOptions()
    }

    static func createMemberStreamOptions() -> PhenixSubscribeToMemberStreamOptions {
        PhenixRoomExpressFactory
            .createSubscribeToMemberStreamOptionsBuilder()
            .buildSubscribeToMemberStreamOptions()
    }

    static func createJoinRoomOptions(alias: String, displayName: String) -> PhenixJoinRoomOptions {
        PhenixRoomExpressFactory.createJoinRoomOptionsBuilder()
            .withRoomAlias(alias)
            .withScreenName(displayName)
            .buildJoinRoomOptions()
    }

    static func createJoinRoomOptions(id: String, displayName: String) -> PhenixJoinRoomOptions {
        PhenixRoomExpressFactory.createJoinRoomOptionsBuilder()
            .withRoomId(id)
            .withScreenName(displayName)
            .buildJoinRoomOptions()
    }

    static func createPublishOptions(with userMediaStream: PhenixUserMediaStream) -> PhenixPublishOptions {
        PhenixPCastExpressFactory.createPublishOptionsBuilder()
            .withUserMedia(userMediaStream)
            .withCapabilities(PhenixConfiguration.capabilities)
            .buildPublishOptions()
    }

    static func createPublishToRoomOptions(
        with roomOptions: PhenixRoomOptions,
        publishOptions: PhenixPublishOptions,
        displayName: String
    ) -> PhenixPublishToRoomOptions {
        PhenixRoomExpressFactory.createPublishToRoomOptionsBuilder()
            .withRoomOptions(roomOptions)
            .withPublishOptions(publishOptions)
            .withScreenName(displayName)
            .buildPublishToRoomOptions()
    }

    static func createSubscribeToMemberAudioStreamOptions(
        streamEndHandler: ((PhenixStreamEndedReason) -> Void)? = nil
    ) -> PhenixSubscribeToMemberStreamOptions {
        let options = PhenixPCastExpressFactory.createMonitorOptionsBuilder().buildMonitorOptions()
        return PhenixRoomExpressFactory.createSubscribeToMemberStreamOptionsBuilder()
            .withCapabilities(["audio-only"])
            .withMonitor(nil, { reason, _, _ in streamEndHandler?(reason) }, options)
            .buildSubscribeToMemberStreamOptions()
    }

    static func createSubscribeToMemberVideoStreamOptions(
        streamEndHandler: ((PhenixStreamEndedReason) -> Void)? = nil
    ) -> PhenixSubscribeToMemberStreamOptions {
        let options = PhenixPCastExpressFactory.createMonitorOptionsBuilder().buildMonitorOptions()
        return PhenixRoomExpressFactory.createSubscribeToMemberStreamOptionsBuilder()
            .withCapabilities(["video-only"])
            .withMonitor(nil, { reason, _, _ in streamEndHandler?(reason) }, options)
            .buildSubscribeToMemberStreamOptions()
    }
}
