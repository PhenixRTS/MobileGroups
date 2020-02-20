/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.phenix.members

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.phenixrts.express.RoomExpress
import com.phenixrts.pcast.Renderer
import com.phenixrts.suite.groups.models.Participant
import com.phenixrts.suite.groups.models.Session
import com.phenixrts.suite.groups.phenix.PhenixException
import com.phenixrts.suite.groups.viewmodels.GroupsViewModel

class LocalMemberPublisher(
    private val roomExpress: RoomExpress,
    private val groups: GroupsViewModel
) : Participant(
    groups.screenName,
    groups.isVideoEnabled,
    groups.isMicrophoneEnabled,
    true
), Session {
    private val internalRenderer = MutableLiveData<Renderer>()
    private val internalError = MutableLiveData<PhenixException>()

    override val errorState: LiveData<PhenixException>
        get() = internalError
    override val renderer: LiveData<Renderer>
        get() = internalRenderer

    override fun connect() {}

    override fun disconnect() {}
}
