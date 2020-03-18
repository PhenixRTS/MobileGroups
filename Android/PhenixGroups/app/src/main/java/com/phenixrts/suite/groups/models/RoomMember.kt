/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import androidx.lifecycle.MutableLiveData
import com.phenixrts.express.ExpressSubscriber
import com.phenixrts.pcast.Renderer
import com.phenixrts.room.Member
import timber.log.Timber

data class RoomMember(
    val member: Member,
    val onUpdate: MutableLiveData<Boolean> = MutableLiveData<Boolean>(),
    var canRenderVideo: Boolean = false,
    var isActiveRenderer: Boolean = false,
    var isPinned: Boolean = false,
    var isMuted: Boolean = false,
    var subscriber: ExpressSubscriber? = null,
    var renderer: Renderer? = null
) {

    fun isSubscribed() = subscriber != null && renderer != null

    fun canRenderThumbnail() = canRenderVideo && !isActiveRenderer

    fun dispose() = try {
        renderer?.stop()
        renderer?.dispose()
        renderer = null
        subscriber?.stop()
        subscriber?.dispose()
        subscriber = null
        Timber.d("Room member disposed: ${toString()}")
    } catch (e: Exception) {
        Timber.d("Failed to dispose room member: ${toString()}")
    }

    override fun toString(): String {
        return "{\"name\":\"${member.observableScreenName.value}\"," +
                "\"canRenderVideo\":\"$canRenderVideo\"," +
                "\"isActiveRenderer\":\"$isActiveRenderer\"," +
                "\"isPinned\":\"$isPinned\"," +
                "\"isMuted\":\"$isMuted\"," +
                "\"isSubscribed\":\"${isSubscribed()}\"}"
    }

}
