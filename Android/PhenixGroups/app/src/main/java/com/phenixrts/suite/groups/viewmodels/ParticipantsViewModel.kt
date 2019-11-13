/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.viewmodels

import androidx.databinding.ObservableArrayList
import androidx.lifecycle.ViewModel
import com.phenixrts.suite.groups.models.Participant
import com.phenixrts.suite.groups.models.RoomModel

class ParticipantsViewModel : ViewModel(), RoomModel.OnMembersEventListener {

    val roomParticipants = ObservableArrayList<Participant>()
    private lateinit var roomModel: RoomModel

    fun initialize(roomModel: RoomModel) {
        this.roomModel = roomModel
        roomModel.addOnMembersEventListener(this)
    }

    override fun onNewMember(participant: Participant) {
        roomParticipants.add(participant)
    }

    override fun onMemberLeft(participant: Participant) {
        roomParticipants.remove(participant)
    }

}