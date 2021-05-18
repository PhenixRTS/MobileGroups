/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import android.os.Handler
import android.os.Looper
import android.view.SurfaceHolder
import android.widget.ImageView
import androidx.lifecycle.MutableLiveData
import com.phenixrts.common.Disposable
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.ExpressSubscriber
import com.phenixrts.media.audio.android.AndroidAudioFrame
import com.phenixrts.media.video.android.AndroidVideoFrame
import com.phenixrts.pcast.*
import com.phenixrts.pcast.android.AndroidReadAudioFrameCallback
import com.phenixrts.pcast.android.AndroidReadVideoFrameCallback
import com.phenixrts.pcast.android.AndroidVideoRenderSurface
import com.phenixrts.room.Member
import com.phenixrts.room.Stream
import com.phenixrts.room.TrackState
import com.phenixrts.suite.groups.BuildConfig
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
    private var subscriptionConfiguration: MemberSubscriptionConfiguration? = null
    private var subscriptionDisposable: Disposable? = null
    private var audioSubscriber: ExpressSubscriber? = null
    private var videoSubscriber: ExpressSubscriber? = null
    private var audioRenderer: Renderer? = null
    private var videoRenderer: Renderer? = null
    private var audioTrack: MediaStreamTrack? = null
    private var videoTrack: MediaStreamTrack? = null
    private var isObserved = false
    private var isRendererStarted = false
    private var readDelay = System.currentTimeMillis()
    private var audioBuffer = arrayListOf<Double>()
    private var mainSurface: SurfaceHolder? = null
    private val memberStream get() = member.observableStreams.value?.getOrNull(0)
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
    private val dataQualityHandler = Handler(Looper.getMainLooper())
    private val dataQualityRunner = Runnable {
        launchMain {
            Timber.d("Data lost for: ${BuildConfig.DATA_QUALITY_TIMEOUT_MS}")
            isDataLost = true
            onUpdate.call(this@RoomMember)
            subscriptionConfiguration?.let { configuration ->
                subscribe(configuration)
            }
        }
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
    var isDataLost = false

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
            audioRenderer?.setFrameReadyCallback(audioTrack, audioFrameCallback)
        }
    }

    private fun observeVideoTrack() {
        if (videoTrack != null) {
            videoRenderer?.setFrameReadyCallback(videoTrack, videoFrameCallback)
        }
    }

    private fun observeDataQuality() {
        if (videoRenderer != null) {
            videoRenderer!!.setDataQualityChangedCallback { _, status, _ ->
                launchMain {
                    val dataLostState = isDataLost
                    if (status == DataQualityStatus.ALL) {
                        isDataLost = false
                        dataQualityHandler.removeCallbacks(dataQualityRunner)
                    } else if (status == DataQualityStatus.NO_DATA) {
                        Timber.d("Render video quality status changed: $status Can show video: $isVideoEnabled : ${this@RoomMember.asString()}")
                        subscriptionConfiguration?.let { configuration ->
                            subscribe(configuration)
                        }
                        dataQualityHandler.postDelayed(dataQualityRunner, BuildConfig.DATA_QUALITY_TIMEOUT_MS)
                    }
                    if (dataLostState != isDataLost) {
                        onUpdate.call(this@RoomMember)
                    }
                }
            }
        } else {
            audioRenderer?.setDataQualityChangedCallback { _, status, _ ->
                launchMain {
                    val dataLostState = isDataLost
                    if (status == DataQualityStatus.ALL) {
                        isDataLost = false
                        dataQualityHandler.removeCallbacks(dataQualityRunner)
                    } else if (status == DataQualityStatus.NO_DATA) {
                        Timber.d("Render audio quality status changed: $status Can play audio: $isAudioEnabled : ${this@RoomMember.asString()}")
                        subscriptionConfiguration?.let { configuration ->
                            subscribe(configuration)
                        }
                        dataQualityHandler.postDelayed(dataQualityRunner, BuildConfig.DATA_QUALITY_TIMEOUT_MS)
                    }
                    if (dataLostState != isDataLost) {
                        onUpdate.call(this@RoomMember)
                    }
                }
            } ?: run {
                isDataLost = true
                onUpdate.call(this@RoomMember)
            }
        }
    }

    private fun updateVolume(decibel: Double) {
        AudioLevel.getVolume(decibel).takeIf { it != audioLevel.value }?.let { volume ->
            audioLevel.postValue(volume)
        }
    }

    private fun updateSubscription(subscriber: ExpressSubscriber? = null, renderer: Renderer? = null,
                                   isVideoStream: Boolean) {
        reset()
        if (isVideoStream) {
            videoSubscriber?.stop()
            videoSubscriber?.dispose()
            videoRenderer?.stop()
            videoRenderer?.dispose()
            videoSubscriber = subscriber
            videoRenderer = renderer
            Timber.d("Video renderer updated: ${asString()}")
        } else {
            audioSubscriber?.stop()
            audioSubscriber?.dispose()
            audioRenderer?.stop()
            audioRenderer?.dispose()
            audioSubscriber = subscriber
            audioRenderer = renderer
            Timber.d("Audio renderer updated: ${asString()}")
        }
    }

    fun isThisMember(sessionId: String?) = member.sessionId == sessionId

    fun getScreenName(): String = member.observableScreenName.value

    fun canRenderThumbnail() = canRenderVideo && isVideoEnabled && !isActiveRenderer

    suspend fun subscribe(configuration: MemberSubscriptionConfiguration) = suspendCancellableCoroutine<Unit> { continuation ->
        if (configuration.roomExpress == null || isSelf) {
            if (continuation.isActive) continuation.resume(Unit)
            return@suspendCancellableCoroutine
        }
        subscriptionConfiguration = configuration
        subscriptionDisposable?.dispose()
        subscriptionDisposable = null
        member.observableStreams.subscribe { streams ->
            Timber.d("Subscribing to member media: ${toString()}")
            currentStreamIndex = 0
            subscribeToStream(configuration, streams.toList(), continuation)
        }.run { subscriptionDisposable = this }
    }

    private fun subscribeToStream(configuration: MemberSubscriptionConfiguration, streams: List<Stream>,
                                  continuation: CancellableContinuation<Unit>){
        streams.getOrNull(currentStreamIndex)?.let { stream ->
            configuration.roomExpress?.subscribeToMemberStream(stream, configuration.options) { status, subscriber, renderer ->
                Timber.d("Subscribed to member media: $status ${toString()}")
                if (status == RequestStatus.OK) {
                    updateSubscription(subscriber, renderer, configuration.isVideoStream)
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
                            subscribeToStream(configuration, streams, continuation)
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
        this.audioRenderer = renderer
        this.videoRenderer = renderer
        this.videoRenderSurface = videoRenderSurface
        this.audioTrack = audioTrack
        this.videoTrack = videoTrack
    }

    fun startMemberRenderer(): RendererStartStatus {
        if (videoRenderer == null) {
            videoRenderer = videoSubscriber?.createRenderer(getRendererOptions())
        }
        if (!isSelf) {
            audioTrack?.run {
                audioRenderer?.setFrameReadyCallback(this, null)
            }
            videoTrack?.run {
                videoRenderer?.setFrameReadyCallback(this, null)
            }
            audioTrack = audioSubscriber?.audioTracks?.getOrNull(0)
            videoTrack = videoSubscriber?.videoTracks?.getOrNull(0)
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
                videoRenderer?.start(videoRenderSurface) ?: RendererStartStatus.FAILED
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
            updateSubscription(isVideoStream = false)
            updateSubscription(isVideoStream = true)
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
