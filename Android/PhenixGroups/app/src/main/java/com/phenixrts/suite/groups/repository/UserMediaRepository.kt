/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import com.phenixrts.common.RequestStatus
import com.phenixrts.express.*
import com.phenixrts.pcast.*
import com.phenixrts.suite.groups.common.extensions.getUserMedia
import com.phenixrts.suite.groups.common.getUserMediaOptions
import com.phenixrts.suite.groups.models.UserMediaStatus
import timber.log.Timber
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class UserMediaRepository(private val roomExpress: RoomExpress) : Repository() {

    private var userMediaStream: UserMediaStream? = null
    private var collectingUserMedia = false

    suspend fun getUserMediaStream(): UserMediaStatus = suspendCoroutine { continuation ->
        launch {
            if (!collectingUserMedia) {
                collectingUserMedia = true
                if (userMediaStream != null) {
                    Timber.d("Returning already collected stream")
                    continuation.resume(UserMediaStatus(userMediaStream = userMediaStream))
                } else {
                    Timber.d("Media stream not collected yet - getting from pCast")
                    val status = roomExpress.pCastExpress.getUserMedia(getUserMediaOptions())
                    userMediaStream = status.userMediaStream
                    continuation.resume(status)
                }
                collectingUserMedia = false
            } else {
                continuation.resume(UserMediaStatus(status = RequestStatus.FAILED))
            }
        }
    }

    fun switchVideoStreamState(enabled: Boolean) = launch {
        Timber.d("Switching video streams: $enabled")
        userMediaStream?.mediaStream?.videoTracks?.forEach { it.isEnabled = enabled }
    }

    fun switchAudioStreamState(enabled: Boolean) = launch {
        Timber.d("Switching audio streams: $enabled")
        userMediaStream?.mediaStream?.audioTracks?.forEach { it.isEnabled = enabled }
    }

}