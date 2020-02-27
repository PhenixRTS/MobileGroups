/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import androidx.lifecycle.MutableLiveData
import com.phenixrts.express.RoomExpress
import com.phenixrts.pcast.*
import com.phenixrts.suite.groups.common.extensions.getUserMedia
import com.phenixrts.suite.groups.models.UserMediaStatus
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.launch
import timber.log.Timber

class UserMediaRepository(private val roomExpress: RoomExpress) : Repository() {

    val userMediaStream = MutableLiveData<UserMediaStream>()

    private val userMediaOptions = UserMediaOptions().apply {
        videoOptions.capabilityConstraints[DeviceCapability.FACING_MODE] = listOf(DeviceConstraint(FacingMode.USER))
        videoOptions.capabilityConstraints[DeviceCapability.HEIGHT] = listOf(DeviceConstraint(480.0))
        videoOptions.capabilityConstraints[DeviceCapability.FRAME_RATE] = listOf(DeviceConstraint(15.0))
        audioOptions.capabilityConstraints[DeviceCapability.AUDIO_ECHO_CANCELATION_MODE] =
            listOf(DeviceConstraint(AudioEchoCancelationMode.ON))
    }

    init {
        launch {
            getUserMediaStream().collect {
                launch(Dispatchers.Main) {
                    Timber.d("Received user media: $it")
                    userMediaStream.value = it.userMediaStream
                }
            }
        }
    }

    private fun getUserMediaStream(): Flow<UserMediaStatus> = flow {
        emit(userMediaStream.value?.let { UserMediaStatus(userMediaStream = it) }
            ?: roomExpress.pCastExpress.getUserMedia(userMediaOptions))
    }

    fun switchVideoStreams(enabled: Boolean) = launch {
        Timber.d("Switching video streams: $enabled")
        userMediaStream.value?.mediaStream?.videoTracks?.forEach { it.isEnabled = enabled }
    }

    fun switchAudioStreams(enabled: Boolean) = launch {
        Timber.d("Switching audio streams: $enabled")
        userMediaStream.value?.mediaStream?.audioTracks?.forEach { it.isEnabled = enabled }
    }

}
