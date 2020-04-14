/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import android.view.SurfaceHolder
import android.view.SurfaceView
import androidx.lifecycle.MutableLiveData
import com.phenixrts.common.Disposable
import com.phenixrts.express.ExpressSubscriber
import com.phenixrts.media.audio.android.AndroidAudioFrame
import com.phenixrts.pcast.FrameNotification
import com.phenixrts.pcast.MediaStreamTrack
import com.phenixrts.pcast.Renderer
import com.phenixrts.pcast.RendererStartStatus
import com.phenixrts.pcast.android.AndroidReadAudioFrameCallback
import com.phenixrts.pcast.android.AndroidVideoRenderSurface
import com.phenixrts.room.Member
import com.phenixrts.room.MemberState
import com.phenixrts.room.TrackState
import com.phenixrts.suite.groups.common.enums.AudioLevel
import com.phenixrts.suite.groups.common.extensions.call
import com.phenixrts.suite.groups.common.extensions.launchMain
import timber.log.Timber
import kotlin.math.abs
import kotlin.math.log10

data class RoomMember(
    var member: Member,
    var isSelf: Boolean
) {

    private val disposables: MutableList<Disposable> = mutableListOf()
    private var videoRenderSurface = AndroidVideoRenderSurface()
    private var subscriber: ExpressSubscriber? = null
    private var renderer: Renderer? = null
    private var audioTrack: MediaStreamTrack? = null
    private var isObserved = false
    private var isAudioObserved = false
    private var isRendererStarted = false
    private var readDelay = System.currentTimeMillis()
    private var audioBuffer = arrayListOf<Double>()
    private var mainSurface: SurfaceHolder? = null
    private var previewSurface: SurfaceHolder? = null

    val onUpdate: MutableLiveData<RoomMember> = MutableLiveData<RoomMember>()
    var audioLevel: MutableLiveData<AudioLevel> = MutableLiveData<AudioLevel>()
    var previewSurfaceView: SurfaceView? = null
    var canRenderVideo = false
    var canShowPreview = false
    var isActiveRenderer = false
    var isPinned = false
    var isMuted = false
    var isOffscreen = false

    private fun observeMember(){
        try {
            if (!isObserved) {
                Timber.d("Observing member: ${toString()}")
                isObserved = true
                val memberStream = member.observableStreams?.value?.getOrNull(0)
                member.observableState?.subscribe {
                    launchMain {
                        if (canRenderVideo && canShowPreview != (it == MemberState.ACTIVE)) {
                            Timber.d("Active state changed: ${this@RoomMember.toString()} state: $it")
                            canShowPreview = it == MemberState.ACTIVE
                            onUpdate.call(this@RoomMember)
                        }
                    }
                }?.run { disposables.add(this) }

                memberStream?.observableVideoState?.subscribe {
                    launchMain {
                        if (canRenderVideo && canShowPreview != (it == TrackState.ENABLED)) {
                            Timber.d("Video state changed: ${this@RoomMember.toString()} state: $it")
                            canShowPreview = it == TrackState.ENABLED
                            onUpdate.call(this@RoomMember)
                        }
                    }
                }?.run { disposables.add(this) }

                memberStream?.observableAudioState?.subscribe {
                    launchMain {
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

    private fun observeAudioTrack(audioTrack: MediaStreamTrack) {
        if (!isAudioObserved) {
            isObserved = renderer != null
            renderer?.setFrameReadyCallback(audioTrack) { frame ->
                readFrame(frame)
            }
        }
    }

    private fun readFrame(frame: FrameNotification) = synchronized(audioBuffer) {
        frame.read(object: AndroidReadAudioFrameCallback() {
            override fun onAudioFrameEvent(audioFrame: AndroidAudioFrame?) {
                audioFrame?.audioSamples?.let { samples ->
                    val now = System.currentTimeMillis()
                    audioBuffer.add(samples.map { abs(it.toInt()) }.average())
                    if (now - readDelay > READ_TIMEOUT_DELAY) {
                        val decibel = 20.0 * log10(audioBuffer.average() / Short.MAX_VALUE)
                        updateVolume(decibel)
                        readDelay = now
                        audioBuffer.clear()
                    }
                }
            }
        })
    }

    private fun updateVolume(decibel: Double) = launchMain {
        AudioLevel.getVolume(decibel).takeIf { it != audioLevel.value }?.let { volume ->
            audioLevel.value = volume
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

    fun setSelfRenderer(renderer: Renderer?, videoRenderSurface: AndroidVideoRenderSurface, audioTrack: MediaStreamTrack?) {
        this.renderer = renderer
        this.videoRenderSurface = videoRenderSurface
        this.audioTrack = audioTrack
    }

    fun startMemberRenderer(): RendererStartStatus {
        if (renderer == null) {
            renderer = subscriber?.createRenderer()
        }
        if (audioTrack == null) {
            audioTrack = subscriber?.audioTracks?.getOrNull(0)
        }
        audioTrack?.let { audioTrack ->
            observeAudioTrack(audioTrack)
        }

        var status = if (canShowPreview) RendererStartStatus.OK else RendererStartStatus.FAILED
        Timber.d("Set surface holder called: ${toString()}")
        videoRenderSurface.setSurfaceHolder(if (isActiveRenderer) mainSurface else previewSurface)
        if (!isRendererStarted && !isSelf) {
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
        if (!isSelf) {
            videoRenderSurface.setSurfaceHolder(null)
            subscriber?.stop()
            subscriber?.dispose()
            subscriber = null
            renderer?.stop()
            renderer?.dispose()
            renderer = null
        }
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

    private companion object {
        private const val READ_TIMEOUT_DELAY = 200
    }

}
