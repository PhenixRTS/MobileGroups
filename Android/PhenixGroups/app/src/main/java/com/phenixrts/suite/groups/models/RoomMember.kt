/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import android.view.SurfaceHolder
import android.view.SurfaceView
import androidx.lifecycle.MutableLiveData
import com.phenixrts.common.Disposable
import com.phenixrts.express.ExpressSubscriber
import com.phenixrts.pcast.Renderer
import com.phenixrts.pcast.RendererStartStatus
import com.phenixrts.pcast.android.AndroidVideoRenderSurface
import com.phenixrts.room.Member
import com.phenixrts.room.MemberState
import com.phenixrts.room.TrackState
import com.phenixrts.suite.groups.common.extensions.call
import timber.log.Timber

data class RoomMember(
    var member: Member,
    var isSelf: Boolean
) : ModelScope() {

    private val disposables: MutableList<Disposable> = mutableListOf()
    private val videoRenderSurface = AndroidVideoRenderSurface()
    private var subscriber: ExpressSubscriber? = null
    private var renderer: Renderer? = null
    private var isObserved = false
    private var isRendererStarted = false

    val onUpdate: MutableLiveData<RoomMember> = MutableLiveData<RoomMember>()
    var mainSurface: SurfaceHolder? = null
    var previewSurface: SurfaceHolder? = null
    var previewSurfaceView: SurfaceView? = null

    var canRenderVideo = false
    var canShowPreview = false
    var isActiveRenderer = false
    var isPinned = false
    var isMuted = false
    var isOffscreen = false

    @Suppress("RemoveToStringInStringTemplate")
    private fun observeMember(){
        try {
            if (!isObserved) {
                Timber.d("Observing member: ${toString()}")
                isObserved = true
                val memberStream = member.observableStreams?.value?.getOrNull(0)
                member.observableState?.subscribe {
                    launch {
                        if (canRenderVideo && canShowPreview != (it == MemberState.ACTIVE)) {
                            Timber.d("Active state changed: ${this@RoomMember.toString()} state: $it")
                            canShowPreview = it == MemberState.ACTIVE
                            onUpdate.call(this@RoomMember)
                        }
                    }
                }?.run { disposables.add(this) }

                memberStream?.observableVideoState?.subscribe {
                    launch {
                        if (canRenderVideo && canShowPreview != (it == TrackState.ENABLED)) {
                            Timber.d("Video state changed: ${this@RoomMember.toString()} state: $it")
                            canShowPreview = it == TrackState.ENABLED
                            onUpdate.call(this@RoomMember)
                        }
                    }
                }?.run { disposables.add(this) }

                memberStream?.observableAudioState?.subscribe {
                    launch {
                        if (isMuted != (it == TrackState.DISABLED)) {
                            Timber.d("Audio state changed: ${this@RoomMember.toString()} state: $it")
                            isMuted = it == TrackState.DISABLED
                            onUpdate.call(this@RoomMember)
                        }
                    }
                }?.run { disposables.add(this) }
            }
        } catch (e: Exception) {
            e.printStackTrace()
            Timber.d("Failed to subscribe to member: ${toString()}")
            isObserved = false
        }
    }

    fun isThisMember(sessionId: String?) = member.sessionId == sessionId

    fun getScreenName(): String = member.observableScreenName.value

    fun isSubscribed() = subscriber != null

    fun canRenderThumbnail() = canRenderVideo && canShowPreview && !isActiveRenderer

    fun onSubscribed(subscriber: ExpressSubscriber, renderer: Renderer?) {
        this.subscriber = subscriber
        this.renderer = renderer
    }

    fun setSurfaces(mainSurface: SurfaceHolder, previewSurface: SurfaceView) {
        this.mainSurface = mainSurface
        this.previewSurface = previewSurface.holder
        this.previewSurfaceView = previewSurface
        if (!isSelf) {
            observeMember()
        }
    }

    fun startMemberRenderer(): RendererStartStatus {
        if (renderer == null) {
            renderer = subscriber?.createRenderer()
        }

        var status = if (canShowPreview) RendererStartStatus.OK else RendererStartStatus.FAILED
        Timber.d("Set surface holder called: ${toString()}")
        videoRenderSurface.setSurfaceHolder(if (isActiveRenderer) mainSurface else previewSurface)
        if (!isRendererStarted) {
            val rendererStartStatus = renderer?.start(videoRenderSurface) ?: RendererStartStatus.FAILED
            isRendererStarted = rendererStartStatus == RendererStartStatus.OK
            status = if (canShowPreview) rendererStartStatus else status
            Timber.d("Started video renderer: $status : ${toString()}")
        }
        return status
    }

    fun dispose() = try {
        isObserved = false
        disposables.forEach { it.dispose() }
        disposables.clear()
        mainSurface = null
        previewSurface = null
        videoRenderSurface.setSurfaceHolder(null)
        Timber.d("Room member disposed: ${toString()}")
    } catch (e: Exception) {
        Timber.d("Failed to dispose room member: ${toString()}")
    }

    override fun toString(): String {
        return "{\"name\":\"${getScreenName()}\"," +
                "\"canRenderVideo\":\"$canRenderVideo\"," +
                "\"canShowPreview\":\"$canShowPreview\"," +
                "\"isActiveRenderer\":\"$isActiveRenderer\"," +
                "\"isPinned\":\"$isPinned\"," +
                "\"isMuted\":\"$isMuted\"," +
                "\"isSelf\":\"$isSelf\"," +
                "\"isSubscribed\":\"${isSubscribed()}\"}"
    }

}
