/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import android.view.SurfaceHolder
import android.widget.ImageView
import androidx.lifecycle.MutableLiveData
import com.phenixrts.common.Disposable
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.ExpressSubscriber
import com.phenixrts.express.RoomExpress
import com.phenixrts.express.SubscribeToMemberStreamOptions
import com.phenixrts.media.audio.android.AndroidAudioFrame
import com.phenixrts.media.video.android.AndroidVideoFrame
import com.phenixrts.pcast.*
import com.phenixrts.pcast.android.AndroidReadAudioFrameCallback
import com.phenixrts.pcast.android.AndroidReadVideoFrameCallback
import com.phenixrts.pcast.android.AndroidVideoRenderSurface
import com.phenixrts.room.Member
import com.phenixrts.room.Stream
import com.phenixrts.room.TrackState
import com.phenixrts.suite.groups.common.enums.AudioLevel
import com.phenixrts.suite.groups.common.extensions.asString
import com.phenixrts.suite.groups.common.extensions.call
import com.phenixrts.suite.groups.common.getRendererOptions
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
    private var videoTrack: MediaStreamTrack? = null
    private var isObserved = false
    private var isRendererStarted = false
    private var readDelay = System.currentTimeMillis()
    private var audioBuffer = arrayListOf<Double>()
    private var mainSurface: SurfaceHolder? = null
    private val memberStream get() = member.observableStreams.value?.get(0)
    private var currentStreamIndex = 0
    private val audioFrameCallback = Renderer.FrameReadyForProcessingCallback { frameNotification ->
        if (isActiveRenderer) return@FrameReadyForProcessingCallback
        frameNotification?.read(object : AndroidReadAudioFrameCallback() {
            override fun onAudioFrameEvent(audioFrame: AndroidAudioFrame?) {
                synchronized(audioBuffer) {
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
            }
        })
    }
    private val videoFrameCallback = Renderer.FrameReadyForProcessingCallback { frameNotification ->
        if (isActiveRenderer) return@FrameReadyForProcessingCallback
        frameNotification?.read(object : AndroidReadVideoFrameCallback() {
            override fun onVideoFrameEvent(videoFrame: AndroidVideoFrame?) {
                launchMain {
                    videoFrame?.bitmap?.let { bitmap ->
                        previewSurface?.setImageBitmap(bitmap.copy(bitmap.config, bitmap.isMutable))
                    }
                }
            }
        })
    }

    val onUpdate: MutableLiveData<RoomMember> = MutableLiveData()
    var audioLevel: MutableLiveData<AudioLevel> = MutableLiveData()
    val isVideoEnabled get() = memberStream?.observableVideoState?.value == TrackState.ENABLED
    val isAudioEnabled get() = memberStream?.observableAudioState?.value == TrackState.ENABLED
    var previewSurface: ImageView? = null
    var canRenderVideo = false
    var isActiveRenderer = false
    var isPinned = false
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
                    if (canRenderVideo) {
                        Timber.d("Active state changed: ${this@RoomMember.asString()} state: $it")
                        onUpdate.call(this@RoomMember)
                    }
                }?.run { disposables.add(this) }

                memberStream?.observableVideoState?.subscribe {
                    if (canRenderVideo) {
                        Timber.d("Video state changed: ${this@RoomMember.asString()} state: $it")
                        onUpdate.call(this@RoomMember)
                    }
                }?.run { disposables.add(this) }

                memberStream?.observableAudioState?.subscribe {
                    Timber.d("Audio state changed: ${this@RoomMember.asString()} state: $it")
                    onUpdate.call(this@RoomMember)
                }?.run { disposables.add(this) }
            }
        } catch (e: Exception) {
            e.printStackTrace()
            Timber.d("Failed to subscribe to member: ${toString()}")
            isObserved = false
        }
    }

    private fun observeAudioTrack() {
        if (audioTrack != null) {
            renderer?.setFrameReadyCallback(audioTrack, audioFrameCallback)
        }
    }

    private fun observeVideoTrack() {
        if (videoTrack != null) {
            renderer?.setFrameReadyCallback(videoTrack, videoFrameCallback)
        }
    }

    private fun observeDataQuality() {
        renderer?.setDataQualityChangedCallback { _, status, _ ->
            if (isVideoEnabled && status != DataQualityStatus.ALL) {
                Timber.d("Render quality status changed: $status Can show video: $isVideoEnabled : ${this@RoomMember.asString()}")
                onUpdate.call(this@RoomMember)
            }
        }
    }

    private fun updateVolume(decibel: Double) {
        AudioLevel.getVolume(decibel).takeIf { it != audioLevel.value }?.let { volume ->
            audioLevel.postValue(volume)
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

    fun canRenderThumbnail() = canRenderVideo && isVideoEnabled && !isActiveRenderer

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
                } else {
                    when {
                        isSubscribed -> {
                            Timber.d("Subscription to member media failed: ${toString()}")
                            reset()
                            onUpdate.call(this)
                        }
                        currentStreamIndex + 1 < streams.size -> {
                            currentStreamIndex++
                            Timber.d("Trying a different stream: $currentStreamIndex")
                            subscribeToStream(roomExpress, options, streams, continuation)
                        }
                        continuation.isActive -> continuation.resume(Unit)
                    }
                }
            }
        }
    }

    fun setSurfaces(mainSurface: SurfaceHolder, previewSurface: ImageView) {
        this.mainSurface = mainSurface
        this.previewSurface = previewSurface
    }

    fun setSelfRenderer(renderer: Renderer?, videoRenderSurface: AndroidVideoRenderSurface,
                        audioTrack: MediaStreamTrack?, videoTrack: MediaStreamTrack?) {
        this.renderer = renderer
        this.videoRenderSurface = videoRenderSurface
        this.audioTrack = audioTrack
        this.videoTrack = videoTrack
    }

    fun startMemberRenderer(): RendererStartStatus {
        if (renderer == null) {
            renderer = subscriber?.createRenderer(getRendererOptions())
        }
        if (!isSelf) {
            audioTrack?.run {
                renderer?.setFrameReadyCallback(this, null)
            }
            videoTrack?.run {
                renderer?.setFrameReadyCallback(this, null)
            }
            audioTrack = subscriber?.audioTracks?.getOrNull(0)
            videoTrack = subscriber?.videoTracks?.getOrNull(0)
        }
        observeMember()
        observeDataQuality()
        observeAudioTrack()
        observeVideoTrack()

        var status = if (isVideoEnabled) RendererStartStatus.OK else RendererStartStatus.FAILED
        Timber.d("Set surface holder called: ${toString()}")
        videoRenderSurface.setSurfaceHolder(if (isActiveRenderer) mainSurface else null)
        if (!isRendererStarted && !isSelf) {
            val rendererStartStatus =
                renderer?.start(videoRenderSurface) ?: RendererStartStatus.FAILED
            isRendererStarted = rendererStartStatus == RendererStartStatus.OK
            status = if (isVideoEnabled) rendererStartStatus else status
            Timber.d("Started video renderer: $status : ${toString()}")
        }
        return status
    }

    private fun reset() {
        currentStreamIndex = 0
        isObserved = false
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
                "\"isVideoEnabled\":\"$isVideoEnabled\"," +
                "\"isAudioEnabled\":\"$isAudioEnabled\"," +
                "\"isActiveRenderer\":\"$isActiveRenderer\"," +
                "\"isPinned\":\"$isPinned\"," +
                "\"isSelf\":\"$isSelf\"," +
                "\"isSubscribed\":\"$isSubscribed\"}"
    }

    private companion object {
        private const val READ_TIMEOUT_DELAY = 200
    }

}
