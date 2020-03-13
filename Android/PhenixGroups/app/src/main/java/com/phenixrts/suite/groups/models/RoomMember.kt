/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import com.phenixrts.express.ExpressSubscriber
import com.phenixrts.pcast.Renderer
import com.phenixrts.room.Member
import com.phenixrts.suite.groups.common.SurfaceIndex

data class RoomMember(
    val member: Member,
    var surface: SurfaceIndex = SurfaceIndex.SURFACE_NONE,
    var subscriber: ExpressSubscriber? = null,
    var renderer: Renderer? = null
) {
    fun isSubscribed() = subscriber != null && renderer != null

    override fun toString(): String {
        return "Member: ${member.observableScreenName.value} Surface: $surface isSubscribed: ${isSubscribed()}"
    }

}
