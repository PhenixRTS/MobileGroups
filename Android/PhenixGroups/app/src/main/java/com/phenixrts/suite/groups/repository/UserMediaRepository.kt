/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import android.os.Handler
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.*
import com.phenixrts.pcast.*
import com.phenixrts.suite.groups.common.extensions.getUserMedia
import com.phenixrts.suite.groups.common.extensions.launchIO
import com.phenixrts.suite.groups.common.getUserMediaOptions
import com.phenixrts.suite.groups.models.UserMediaStatus
import timber.log.Timber
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class UserMediaRepository(private val roomExpress: RoomExpress) {

    private var userMediaStream: UserMediaStream? = null
    private var collectingUserMedia = false
    private var currentFacingMode = FacingMode.USER
    private var mediaStateCallback: OnMediaStateChange? = null

    private val audioFailureHandler = Handler()
    private val videoFailureHandler = Handler()
    private val audioFailureRunnable = Runnable {
        Timber.d("Audio recording has stopped")
        mediaStateCallback?.onMicrophoneLost()
    }
    private val videoFailureRunnable = Runnable {
        Timber.d("Video recording is stopped")
        mediaStateCallback?.onCameraLost()
    }

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

    suspend fun getUserMediaStream(): UserMediaStatus = suspendCoroutine { continuation ->
        launchIO {
            if (!collectingUserMedia) {
                collectingUserMedia = true
                if (userMediaStream != null) {
                    Timber.d("Returning already collected stream")
                    continuation.resume(UserMediaStatus(userMediaStream = userMediaStream))
                } else {
                    Timber.d("Media stream not collected yet - getting from pCast")
                    val status = roomExpress.pCastExpress.getUserMedia(getUserMediaOptions())
                    userMediaStream = status.userMediaStream
                    observeMediaStreams()
                    continuation.resume(status)
                }
                collectingUserMedia = false
            } else {
                continuation.resume(UserMediaStatus(status = RequestStatus.FAILED))
            }
        }
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

    interface OnMediaStateChange {
        fun onMicrophoneLost()
        fun onCameraLost()
    }

    private companion object {
        // The timeout after we can assume that the video or audio pipeline is terminated
        private const val FAILURE_TIMEOUT = 1000 * 3L
    }

}
