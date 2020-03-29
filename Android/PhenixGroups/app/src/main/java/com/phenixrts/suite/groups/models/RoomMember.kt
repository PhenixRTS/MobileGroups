/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import android.view.SurfaceHolder
import androidx.lifecycle.MutableLiveData
import com.phenixrts.common.Disposable
import com.phenixrts.express.ExpressSubscriber
import com.phenixrts.pcast.Renderer
import com.phenixrts.pcast.RendererStartStatus
import com.phenixrts.pcast.android.AndroidVideoRenderSurface
import com.phenixrts.room.Member
import timber.log.Timber

data class RoomMember(val member: Member) {

    private val disposables: MutableList<Disposable> = mutableListOf()
    private val videoRenderSurface = AndroidVideoRenderSurface()
    private var subscriber: ExpressSubscriber? = null
    private var renderer: Renderer? = null

    val onUpdate: MutableLiveData<Boolean> = MutableLiveData<Boolean>()
    var mainSurface: SurfaceHolder? = null
    var previewSurface: SurfaceHolder? = null

    var canRenderVideo = false
    var canShowPreview = false
    var isRendererStarted = false
    var isActiveRenderer = false
    var isPinned = false
    var isMuted = false

    fun isSubscribed() = subscriber != null && renderer != null

    fun canRenderThumbnail() = canRenderVideo && canShowPreview && !isActiveRenderer

    fun onSubscribed(subscriber: ExpressSubscriber, renderer: Renderer?) {
        this.subscriber = subscriber
        this.renderer = renderer
    }

    fun setSurfaces(mainSurface: SurfaceHolder, previewSurface: SurfaceHolder) {
        this.mainSurface = mainSurface
        this.previewSurface = previewSurface
        Timber.d("Added member surfaces: ${toString()}")
    }

    fun startMemberRenderer(): RendererStartStatus {
        if (renderer == null) {
            renderer = subscriber?.createRenderer()
        }

        var status = RendererStartStatus.OK
        Timber.d("Updating renderer surface: $mainSurface $previewSurface")
        videoRenderSurface.setSurfaceHolder(if (isActiveRenderer) mainSurface else previewSurface)
        if (!isRendererStarted) {
            status = renderer?.start(videoRenderSurface) ?: RendererStartStatus.FAILED
            isRendererStarted = status == RendererStartStatus.OK
            Timber.d("Started video renderer: $status : ${toString()}")
        }
        return status
    }

    fun addDisposable(disposable: Disposable) {
        disposables.add(disposable)
    }

    fun dispose() = try {
        disposables.forEach { it.dispose() }
        disposables.clear()
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
                "\"canShowPreview\":\"$canShowPreview\"," +
                "\"isActiveRenderer\":\"$isActiveRenderer\"," +
                "\"isPinned\":\"$isPinned\"," +
                "\"isMuted\":\"$isMuted\"," +
                "\"isSubscribed\":\"${isSubscribed()}\"}"
    }

}
