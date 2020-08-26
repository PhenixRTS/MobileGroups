/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import android.os.Handler
import android.os.Looper
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

    private val microphoneFailureHandler = Handler(Looper.getMainLooper())
    private val cameraFailureHandler = Handler(Looper.getMainLooper())
    private val microphoneFailureRunnable = Runnable {
        if (!isDisposed) {
            Timber.d("Audio recording has stopped")
            mediaStateCallback?.onMicrophoneStateChanged(false)
            isMicrophoneAvailable = false
        }
    }
    private val videoFailureRunnable = Runnable {
        if (!isDisposed) {
            Timber.d("Video recording is stopped")
            mediaStateCallback?.onCameraStateChanged(false)
            isCameraAvailable = false
        }
    }
    private var isMicrophoneAvailable = false
    private var isCameraAvailable = false

    var userMediaStream: UserMediaStream? = null

    private fun observeMediaStreams() {
        userMediaStream?.apply {
            mediaStream.videoTracks.getOrNull(0)?.let { videoTrack ->
                setFrameReadyCallback(videoTrack) {
                    if (!isCameraAvailable) {
                        mediaStateCallback?.onCameraStateChanged(true)
                        isCameraAvailable = true
                    }
                    cameraFailureHandler.removeCallbacks(videoFailureRunnable)
                    cameraFailureHandler.postDelayed(videoFailureRunnable, FAILURE_TIMEOUT)
                }
            }
            mediaStream.audioTracks.getOrNull(0)?.let { audioTrack ->
                setFrameReadyCallback(audioTrack) {
                    if (!isMicrophoneAvailable) {
                        mediaStateCallback?.onMicrophoneStateChanged(true)
                        isMicrophoneAvailable = true
                    }
                    microphoneFailureHandler.removeCallbacks(microphoneFailureRunnable)
                    microphoneFailureHandler.postDelayed(microphoneFailureRunnable, FAILURE_TIMEOUT)
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

    fun dispose() {
        isDisposed = true
        Timber.d("User media repository disposed")
    }

    interface OnMediaStateChange {
        fun onMicrophoneStateChanged(available: Boolean)
        fun onCameraStateChanged(available: Boolean)
    }

    private companion object {
        // The timeout after we can assume that the video or audio pipeline is terminated
        private const val FAILURE_TIMEOUT = 1000 * 3L
    }

}
