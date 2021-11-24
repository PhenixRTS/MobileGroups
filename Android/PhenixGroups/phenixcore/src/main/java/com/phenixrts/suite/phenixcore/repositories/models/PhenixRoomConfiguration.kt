/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.phenixcore.repositories.models

import com.phenixrts.room.MemberRole
import com.phenixrts.room.RoomType
import com.phenixrts.suite.phenixcore.BuildConfig

data class PhenixRoomConfiguration(
    var roomId: String = "",
    var roomAlias: String = "",
    var roomType: RoomType = RoomType.MULTI_PARTY_CHAT,
    var roomAudioToken: String? = null,
    var roomVideoToken: String? = null,
    var memberName: String = "",
    var memberRole: MemberRole = MemberRole.AUDIENCE,
    var messageConfigs: List<PhenixMessageConfiguration> = emptyList(),
    var joinSilently: Boolean = false,
    var maxVideoRenderers: Int = BuildConfig.MAX_VIDEO_RENDERERS
)
