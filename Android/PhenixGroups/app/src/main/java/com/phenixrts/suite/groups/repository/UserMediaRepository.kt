/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import android.os.Handler
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.*
import com.phenixrts.pcast.*
import com.phenixrts.suite.groups.common.extensions.getUserMedia
import com.phenixrts.suite.groups.common.getUserMediaOptions
import com.phenixrts.suite.phenixcommon.common.launchIO
import timber.log.Timber
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class UserMediaRepository(private val roomExpress: RoomExpress) {

    private var currentFacingMode = FacingMode.USER
    private var mediaStateCallback: OnMediaStateChange? = null
    private var isDisposed = false

    private val audioFailureHandler = Handler()
    private val videoFailureHandler = Handler()
    private val audioFailureRunnable = Runnable {
        if (!isDisposed) {
            Timber.d("Audio recording has stopped")
            mediaStateCallback?.onMicrophoneLost()
        }
    }
    private val videoFailureRunnable = Runnable {
        if (!isDisposed) {
            Timber.d("Video recording is stopped")
            mediaStateCallback?.onCameraLost()
        }
    }

    var userMediaStream: UserMediaStream? = null

    private fun observeMediaStreams() {
        userMediaStream?.apply {
            mediaStream.videoTracks.getOrNull(0)?.let { videoTrack ->
                setFrameReadyCallback(videoTrack) {
                    videoFailureHandler.removeCallbacks(videoFailureRunnable)
                    videoFailureHandler.postDelayed(videoFailureRunnable, FAILURE_TIMEOUT)
                }
            }
            mediaStream.audioTracks.getOrNull(0)?.let { audioTrack ->
                setFrameReadyCallback(audioTrack) {
                    audioFailureHandler.removeCallbacks(audioFailureRunnable)
                    audioFailureHandler.postDelayed(audioFailureRunnable, FAILURE_TIMEOUT)
                }
            }
        }
    }

    suspend fun waitForUserStream(): RequestStatus {
        Timber.d("Media stream not collected yet - getting from pCast")
        val userMediaStatus = roomExpress.pCastExpress.getUserMedia(getUserMediaOptions())
        Timber.d("Media stream collected from pCast")
        userMediaStream = userMediaStatus.userMediaStream
        observeMediaStreams()
        return userMediaStatus.status
    }

    suspend fun switchCameraFacing(): RequestStatus = suspendCoroutine { continuation ->
        launchIO {
            val facingMode = if (currentFacingMode == FacingMode.USER) FacingMode.ENVIRONMENT else FacingMode.USER
            var requestStatus = RequestStatus.FAILED
            userMediaStream?.applyOptions(getUserMediaOptions(facingMode))?.let { status ->
                requestStatus = status
                if (status == RequestStatus.OK) {
                    currentFacingMode = facingMode
                }
            }
            continuation.resume(requestStatus)
        }
    }

    fun switchVideoStreamState(enabled: Boolean) = launchIO {
        Timber.d("Switching video streams: $enabled")
        userMediaStream?.mediaStream?.videoTracks?.forEach { it.isEnabled = enabled }
    }

    fun switchAudioStreamState(enabled: Boolean) = launchIO {
        Timber.d("Switching audio streams: $enabled")
        userMediaStream?.mediaStream?.audioTracks?.forEach { it.isEnabled = enabled }
    }

    fun observeMediaState(callback: OnMediaStateChange) {
        mediaStateCallback = callback
    }

    fun dispose() = try {
        isDisposed = true
        // TODO: User media cannot be disposed without breaking the rendering and streaming
        //userMediaStream?.dispose()
        Timber.d("User media repository disposed")
    } catch (e: Exception) {
        Timber.d("Failed to dispose user media repository")
    }

    interface OnMediaStateChange {
        fun onMicrophoneLost()
        fun onCameraLost()
    }

    private companion object {
        // The timeout after we can assume that the video or audio pipeline is terminated
        private const val FAILURE_TIMEOUT = 1000 * 3L
    }

}
