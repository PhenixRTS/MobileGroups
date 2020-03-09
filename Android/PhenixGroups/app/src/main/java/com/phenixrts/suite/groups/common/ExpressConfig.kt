/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common

import android.view.SurfaceHolder
import com.phenixrts.express.*
import com.phenixrts.pcast.UserMediaStream
import com.phenixrts.pcast.android.AndroidVideoRenderSurface
import com.phenixrts.room.RoomOptions
import com.phenixrts.room.RoomServiceFactory
import com.phenixrts.room.RoomType

fun getPublishOptions(userMediaStream: UserMediaStream): PublishOptions = PCastExpressFactory.createPublishOptionsBuilder()
    .withUserMedia(userMediaStream)
    .withCapabilities(arrayOf("sd", "multi-bitrate"))
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

fun getSubscribeOptions(surfaceHolder: SurfaceHolder): SubscribeToMemberStreamOptions =
    RoomExpressFactory.createSubscribeToMemberStreamOptionsBuilder()
        .withRenderer(AndroidVideoRenderSurface(surfaceHolder))
        .buildSubscribeToMemberStreamOptions()
