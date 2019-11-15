/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.phenix.members

import android.util.Log
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.Transformations
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.ExpressSubscriber
import com.phenixrts.express.RoomExpressFactory
import com.phenixrts.pcast.Renderer
import com.phenixrts.room.Member
import com.phenixrts.room.TrackState
import com.phenixrts.suite.groups.models.Participant
import com.phenixrts.suite.groups.models.Session
import com.phenixrts.suite.groups.phenix.PhenixComponent
import com.phenixrts.suite.groups.phenix.PhenixException
import com.phenixrts.suite.groups.phenix.toMutableLiveData
import com.phenixrts.suite.groups.utils.TAG

class RemoteMemberSubscriber(val member: Member) : Participant(
    member.observableScreenName.toMutableLiveData(),
    Transformations.map(member.observableStreams.value.first().observableVideoState.toMutableLiveData()) { it == TrackState.ENABLED },
    Transformations.map(member.observableStreams.value.first().observableAudioState.toMutableLiveData()) { it == TrackState.ENABLED },
    false
), Session {
    private var subscriber: ExpressSubscriber? = null
    private val internalRenderer = MutableLiveData<Renderer>()
    private val internalError = MutableLiveData<PhenixException>()

    override val errorState: LiveData<PhenixException>
        get() = internalError
    override val renderer: LiveData<Renderer>
        get() = internalRenderer

    override fun connect() = subscribe()

    override fun disconnect() {
        internalRenderer.value?.stop()
        internalRenderer.value?.dispose()
        internalRenderer.postValue(null)
        internalError.postValue(null)
        subscriber?.stop()
        subscriber?.dispose()
        subscriber = null
    }

    private fun subscribe() {
        val stream = member.observableStreams.value.firstOrNull()
            ?: throw IllegalStateException("Member doesn't have a stream")

        val options = RoomExpressFactory.createSubscribeToMemberStreamOptionsBuilder()
            .buildSubscribeToMemberStreamOptions()

        PhenixComponent.roomExpress.subscribeToMemberStream(
            stream,
            options
        ) { status, subscriber, _ ->
            when (status) {
                RequestStatus.OK -> {
                    this.subscriber = subscriber
                    internalRenderer.value?.stop()
                    internalRenderer.value?.dispose()
                    internalRenderer.postValue(subscriber.createRenderer())
                    internalError.postValue(null)
                }
                else -> {
                    Log.e(TAG, "Cannot subscribe to [${member.observableScreenName.value}]")
                    internalRenderer.value?.stop()
                    internalRenderer.value?.dispose()
                    internalRenderer.postValue(null)
                    internalError.postValue(PhenixException(status))
                }
            }
        }
    }

    override fun equals(other: Any?): Boolean {
        return member == (other as? RemoteMemberSubscriber)?.member
    }

    override fun hashCode(): Int {
        return member.hashCode()
    }
}