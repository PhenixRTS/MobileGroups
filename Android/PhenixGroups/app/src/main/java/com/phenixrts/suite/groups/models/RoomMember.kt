/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import android.view.SurfaceHolder
import android.view.SurfaceView
import androidx.lifecycle.MutableLiveData
import com.phenixrts.common.Disposable
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.ExpressSubscriber
import com.phenixrts.express.RoomExpress
import com.phenixrts.express.SubscribeToMemberStreamOptions
import com.phenixrts.media.audio.android.AndroidAudioFrame
import com.phenixrts.pcast.*
import com.phenixrts.pcast.android.AndroidReadAudioFrameCallback
import com.phenixrts.pcast.android.AndroidVideoRenderSurface
import com.phenixrts.room.Member
import com.phenixrts.room.MemberState
import com.phenixrts.room.Stream
import com.phenixrts.room.TrackState
import com.phenixrts.suite.groups.common.enums.AudioLevel
import com.phenixrts.suite.groups.common.extensions.asString
import com.phenixrts.suite.groups.common.extensions.call
import com.phenixrts.suite.groups.common.getRendererOptions
import com.phenixrts.suite.phenixcommon.common.launchIO
import com.phenixrts.suite.phenixcommon.common.launchMain
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.suspendCancellableCoroutine
import timber.log.Timber
import kotlin.coroutines.resume
import kotlin.math.abs
import kotlin.math.log10

data class RoomMember(
    var member: Member,
    var isSelf: Boolean
) {

    private val disposables: MutableList<Disposable> = mutableListOf()
    private var videoRenderSurface = AndroidVideoRenderSurface()
    private var subscriptionDisposable: Disposable? = null
    private var subscriber: ExpressSubscriber? = null
    private var renderer: Renderer? = null
    private var audioTrack: MediaStreamTrack? = null
    private var isObserved = false
    private var isAudioObserved = false
    private var isRendererStarted = false
    private var isQualityObserved = false
    private var readDelay = System.currentTimeMillis()
    private var audioBuffer = arrayListOf<Double>()
    private var mainSurface: SurfaceHolder? = null
    private var previewSurface: SurfaceHolder? = null
    private var currentStreamIndex = 0

    val onUpdate: MutableLiveData<RoomMember> = MutableLiveData()
    var audioLevel: MutableLiveData<AudioLevel> = MutableLiveData()
    var previewSurfaceView: SurfaceView? = null
    var canRenderVideo = false
    var canShowPreview = false
    var isActiveRenderer = false
    var isPinned = false
    var isMuted = false
    var isOffscreen = false
    var isSubscribed = false

    private fun observeMember() {
        try {
            if (!isObserved && !isSelf) {
                Timber.d("Observing member: ${toString()}")
                isObserved = true
                disposables.forEach { it.dispose() }
                disposables.clear()
                val memberStream = member.observableStreams?.value?.getOrNull(0)
                member.observableState?.subscribe {
                    launchMain {
                        if (canRenderVideo && canShowPreview != (it == MemberState.ACTIVE)) {
                            Timber.d("Active state changed: ${this@RoomMember.asString()} state: $it")
                            canShowPreview = it == MemberState.ACTIVE
                            onUpdate.call(this@RoomMember)
                        }
                    }
                }?.run { disposables.add(this) }

                memberStream?.observableVideoState?.subscribe {
                    launchMain {
                        if (canRenderVideo && canShowPreview != (it == TrackState.ENABLED)) {
                            Timber.d("Video state changed: ${this@RoomMember.asString()} state: $it")
                            canShowPreview = it == TrackState.ENABLED
                            onUpdate.call(this@RoomMember)
                        }
                    }
                }?.run { disposables.add(this) }

                memberStream?.observableAudioState?.subscribe {
                    launchMain {
                        if (isMuted != (it == TrackState.DISABLED)) {
                            Timber.d("Audio state changed: ${this@RoomMember.asString()} state: $it")
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

    private fun observeDataQuality() {
        if (!isQualityObserved) {
            isQualityObserved = true
            renderer?.setDataQualityChangedCallback { _, status, _ ->
                launchMain {
                    if (canShowPreview && status != DataQualityStatus.ALL) {
                        Timber.d("Render quality status changed: $status Can show video: $canShowPreview : ${this@RoomMember.asString()}")
                        canShowPreview = false
                        onUpdate.call(this@RoomMember)
                    }
                }
            }
        }
    }

    private fun readFrame(frame: FrameNotification) = synchronized(audioBuffer) {
        frame.read(object : AndroidReadAudioFrameCallback() {
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

    private fun updateSubscription(subscriber: ExpressSubscriber? = null, renderer: Renderer? = null) {
        // Dispose old subscription and renderer
        reset()
        this.subscriber?.stop()
        this.subscriber?.dispose()
        this.renderer?.stop()
        this.renderer?.dispose()

        // Assign new values
        this.subscriber = subscriber
        this.renderer = renderer
    }

    fun isThisMember(sessionId: String?) = member.sessionId == sessionId

    fun getScreenName(): String = member.observableScreenName.value

    fun canRenderThumbnail() = canRenderVideo && canShowPreview && !isActiveRenderer

    suspend fun subscribe(roomExpress: RoomExpress?, options: SubscribeToMemberStreamOptions) = suspendCancellableCoroutine<Unit> { continuation ->
        if (roomExpress == null || isSelf) {
            if (continuation.isActive) continuation.resume(Unit)
            return@suspendCancellableCoroutine
        }
        subscriptionDisposable?.dispose()
        subscriptionDisposable = null
        member.observableStreams.subscribe { streams ->
            Timber.d("Subscribing to member media: ${toString()}")
            subscribeToStream(roomExpress, options, streams.toList(), continuation)
        }.run { subscriptionDisposable = this }
    }

    private fun subscribeToStream(roomExpress: RoomExpress, options: SubscribeToMemberStreamOptions,
                                          streams: List<Stream>, continuation: CancellableContinuation<Unit>){
        streams.getOrNull(currentStreamIndex)?.let { stream ->
            roomExpress.subscribeToMemberStream(stream, options) { status, subscriber, renderer ->
                Timber.d("Subscribed to member media: $status ${toString()}")
                if (status == RequestStatus.OK) {
                    updateSubscription(subscriber, renderer)
                    startMemberRenderer()
                    isSubscribed = true
                    if (continuation.isActive) continuation.resume(Unit)
                } else if (currentStreamIndex + 1 < streams.size) {
                    launchIO {
                        currentStreamIndex++
                        Timber.d("Trying a different stream: $currentStreamIndex")
                        subscribeToStream(roomExpress, options, streams, continuation)
                    }
                } else if (continuation.isActive) continuation.resume(Unit)
            }
        }
    }

    fun setSurfaces(mainSurface: SurfaceHolder, previewSurface: SurfaceView) {
        this.mainSurface = mainSurface
        this.previewSurface = previewSurface.holder
        this.previewSurfaceView = previewSurface
    }

    fun setSelfRenderer(renderer: Renderer?, videoRenderSurface: AndroidVideoRenderSurface, audioTrack: MediaStreamTrack?) {
        this.renderer = renderer
        this.videoRenderSurface = videoRenderSurface
        this.audioTrack = audioTrack
    }

    fun startMemberRenderer(): RendererStartStatus {
        if (renderer == null) {
            renderer = subscriber?.createRenderer(getRendererOptions())
        }
        if (audioTrack == null) {
            audioTrack = subscriber?.audioTracks?.getOrNull(0)
        }
        observeMember()
        observeDataQuality()
        audioTrack?.let { audioTrack ->
            observeAudioTrack(audioTrack)
        }

        var status = if (canShowPreview) RendererStartStatus.OK else RendererStartStatus.FAILED
        Timber.d("Set surface holder called: ${toString()}")
        videoRenderSurface.setSurfaceHolder(if (isActiveRenderer) mainSurface else previewSurface)
        if (!isRendererStarted && !isSelf) {
            val rendererStartStatus =
                renderer?.start(videoRenderSurface) ?: RendererStartStatus.FAILED
            isRendererStarted = rendererStartStatus == RendererStartStatus.OK
            status = if (canShowPreview) rendererStartStatus else status
            Timber.d("Started video renderer: $status : ${toString()}")
        }
        return status
    }

    private fun reset() {
        currentStreamIndex = 0
        isObserved = false
        isAudioObserved = false
        isSubscribed = false
        isRendererStarted = false
    }

    fun dispose() = try {
        reset()
        disposables.forEach { it.dispose() }
        disposables.clear()
        subscriptionDisposable?.dispose()
        subscriptionDisposable = null
        mainSurface = null
        previewSurface = null
        if (!isSelf) {
            videoRenderSurface.setSurfaceHolder(null)
            updateSubscription()
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
                "\"isSubscribed\":\"$isSubscribed\"}"
    }

    private companion object {
        private const val READ_TIMEOUT_DELAY = 200
    }

}
