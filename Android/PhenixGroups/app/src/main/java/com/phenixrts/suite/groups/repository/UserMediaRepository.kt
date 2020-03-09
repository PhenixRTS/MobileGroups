/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import com.phenixrts.common.RequestStatus
import com.phenixrts.express.*
import com.phenixrts.pcast.*
import com.phenixrts.room.Stream
import com.phenixrts.suite.groups.common.extensions.getUserMedia
import com.phenixrts.suite.groups.models.RoomStatus
import com.phenixrts.suite.groups.models.UserMediaStatus
import timber.log.Timber
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class UserMediaRepository(private val roomExpress: RoomExpress) : Repository() {

    private val subscribers: MutableList<ExpressSubscriber> = mutableListOf()
    private var userMediaStream: UserMediaStream? = null
    private var collectingUserMedia = false

    private val userMediaOptions = UserMediaOptions().apply {
        videoOptions.capabilityConstraints[DeviceCapability.FACING_MODE] = listOf(DeviceConstraint(FacingMode.USER))
        videoOptions.capabilityConstraints[DeviceCapability.HEIGHT] = listOf(DeviceConstraint(480.0))
        videoOptions.capabilityConstraints[DeviceCapability.FRAME_RATE] = listOf(DeviceConstraint(15.0))
        audioOptions.capabilityConstraints[DeviceCapability.AUDIO_ECHO_CANCELATION_MODE] =
            listOf(DeviceConstraint(AudioEchoCancelationMode.ON))
    }

    suspend fun getUserMediaStream(): UserMediaStatus = suspendCoroutine { continuation ->
        launch {
            if (!collectingUserMedia) {
                collectingUserMedia = true
                if (userMediaStream != null) {
                    Timber.d("Returning already collected stream")
                    collectingUserMedia = false
                    continuation.resume(UserMediaStatus(userMediaStream = userMediaStream))
                } else {
                    Timber.d("Media stream not collected yet - getting from pCast")
                    val status = roomExpress.pCastExpress.getUserMedia(userMediaOptions)
                    userMediaStream = status.userMediaStream
                    collectingUserMedia = false
                    continuation.resume(status)
                }
            } else {
                continuation.resume(UserMediaStatus(status = RequestStatus.FAILED))
            }
        }
    }

    suspend fun subscribeToMemberMedia(stream: Stream, options: SubscribeToMemberStreamOptions): RoomStatus = suspendCoroutine { continuation ->
        roomExpress.subscribeToMemberStream(stream, options) {status, subscriber, renderer ->
            var message = ""
            if (status == RequestStatus.OK && renderer != null) {
                renderer.start()
            } else {
                message = "Failed to subscribe to member media"
            }
            subscribers.add(subscriber)
            continuation.resume(RoomStatus(status, message))
        }
    }

    fun switchVideoStreams(enabled: Boolean) = launch {
        Timber.d("Switching video streams: $enabled")
        userMediaStream?.mediaStream?.videoTracks?.forEach { it.isEnabled = enabled }
    }

    fun switchAudioStreams(enabled: Boolean) = launch {
        Timber.d("Switching audio streams: $enabled")
        userMediaStream?.mediaStream?.audioTracks?.forEach { it.isEnabled = enabled }
    }

}
