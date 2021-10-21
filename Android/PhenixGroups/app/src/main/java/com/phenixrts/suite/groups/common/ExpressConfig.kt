/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common

import com.phenixrts.express.*
import com.phenixrts.pcast.*
import com.phenixrts.room.RoomOptions
import com.phenixrts.room.RoomServiceFactory
import com.phenixrts.room.RoomType
import com.phenixrts.suite.groups.BuildConfig
import com.phenixrts.suite.phenixdeeplink.models.PhenixDeepLinkConfiguration

val DEFAULT_CONFIG get() = PhenixDeepLinkConfiguration(
    authToken = "",
    rawActs = "",
    backend = BuildConfig.BACKEND_URL,
    rawChannelAliases = "",
    edgeToken = "",
    rawStreamTokens = "",
    rawMimeTypes = "",
    publishToken = "",
    rawStreamIDs = "",
    uri = BuildConfig.PCAST_URL,
    maxVideoMembers = BuildConfig.MAX_VIDEO_MEMBERS.toString()
)

fun getPublishOptions(userMediaStream: UserMediaStream): PublishOptions = PCastExpressFactory.createPublishOptionsBuilder()
    .withUserMedia(userMediaStream)
    .withCapabilities(arrayOf("ld", "multi-bitrate", "prefer-h264"))
    .buildPublishOptions()

fun getRoomOptions(roomAlias: String): RoomOptions = RoomServiceFactory.createRoomOptionsBuilder()
    .withAlias(roomAlias)
    .withName(roomAlias)
    .withType(RoomType.MULTI_PARTY_CHAT)
    .buildRoomOptions()

fun getPublishToRoomOptions(roomId: String, userScreenName: String, publishOptions: PublishOptions): PublishToRoomOptions =
    RoomExpressFactory.createPublishToRoomOptionsBuilder()
        .withRoomId(roomId)
        .withPublishOptions(publishOptions)
        .withScreenName(userScreenName)
        .buildPublishToRoomOptions()

fun getPublishToRoomOptions(userScreenName: String, roomOptions: RoomOptions, publishOptions: PublishOptions): PublishToRoomOptions =
    RoomExpressFactory.createPublishToRoomOptionsBuilder()
        .withRoomOptions(roomOptions)
        .withPublishOptions(publishOptions)
        .withScreenName(userScreenName)
        .buildPublishToRoomOptions()

fun getSubscribeVideoOptions(): SubscribeToMemberStreamOptions =
    RoomExpressFactory.createSubscribeToMemberStreamOptionsBuilder()
        .withCapabilities(arrayOf("video-only"))
        .buildSubscribeToMemberStreamOptions()

fun getSubscribeAudioOptions(): SubscribeToMemberStreamOptions =
    RoomExpressFactory.createSubscribeToMemberStreamOptionsBuilder()
        .withCapabilities(arrayOf("audio-only"))
        .withAudioOnlyRenderer()
        .buildSubscribeToMemberStreamOptions()

fun getUserMediaOptions(facingMode: FacingMode = FacingMode.USER): UserMediaOptions = UserMediaOptions().apply {
    videoOptions.capabilityConstraints[DeviceCapability.FACING_MODE] = listOf(DeviceConstraint(facingMode))
    videoOptions.capabilityConstraints[DeviceCapability.HEIGHT] = listOf(DeviceConstraint(360.0))
    videoOptions.capabilityConstraints[DeviceCapability.FRAME_RATE] = listOf(DeviceConstraint(15.0))
    audioOptions.capabilityConstraints[DeviceCapability.AUDIO_ECHO_CANCELATION_MODE] =
        listOf(DeviceConstraint(AudioEchoCancelationMode.ON))
}

fun getRendererOptions(): RendererOptions = RendererOptions().apply {
    audioEchoCancelationMode = AudioEchoCancelationMode.ON
}
