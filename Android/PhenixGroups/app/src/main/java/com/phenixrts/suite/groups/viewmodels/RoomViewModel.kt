/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.viewmodels

import androidx.databinding.ObservableArrayList
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import com.phenixrts.suite.groups.models.Participant
import com.phenixrts.suite.groups.models.UserSettings

class RoomViewModel : ViewModel() {

    private val TAG = RoomViewModel::class.java.simpleName

    val activeParticipant: MutableLiveData<Participant> = MutableLiveData()
    val roomParticipants = ObservableArrayList<Participant>()

    fun startCall(userSettings: UserSettings) {

        val localParticipant = userSettings.toParticipant()
        roomParticipants.add(localParticipant)
        activeParticipant.value = localParticipant

        // subscribe to room and observe members
        // - update roomParticipants

        // publish local user media

    }

    fun endCall() {
        activeParticipant.value = null
        roomParticipants.clear()
    }

    private fun UserSettings.toParticipant(): Participant {
        return Participant(nickname, isVideoEnabled, isMicrophoneEnabled, isLocal = true)
    }
}