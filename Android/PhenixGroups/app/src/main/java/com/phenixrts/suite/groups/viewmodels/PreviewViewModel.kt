/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.viewmodels

import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import com.phenixrts.suite.groups.models.Participant
import com.phenixrts.suite.groups.models.RoomModel

class PreviewViewModel : ViewModel(), RoomModel.OnMembersEventListener {
    val participantInVideoPreview = MutableLiveData<Participant>()

    fun initialize(roomModel: RoomModel) {
        roomModel.addOnMembersEventListener(this)
    }

    override fun onNewMember(participant: Participant) {
        participant.renderer.value?.start()
        if (participantInVideoPreview.value == null) {
            participantInVideoPreview.value = participant
        }
    }

    override fun onMemberLeft(participant: Participant) {
        participant.renderer.value?.stop()
        if (participant == participantInVideoPreview.value) {
            participantInVideoPreview.value = null
        }
    }
}