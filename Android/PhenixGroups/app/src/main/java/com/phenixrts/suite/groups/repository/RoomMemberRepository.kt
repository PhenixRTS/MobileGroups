/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import androidx.lifecycle.MutableLiveData
import com.phenixrts.common.Disposable
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.RoomExpress
import com.phenixrts.express.SubscribeToMemberStreamOptions
import com.phenixrts.room.Member
import com.phenixrts.room.RoomService
import com.phenixrts.suite.groups.common.SurfaceIndex
import com.phenixrts.suite.groups.common.extensions.getFromList
import com.phenixrts.suite.groups.models.RoomStatus
import com.phenixrts.suite.groups.models.RoomMember
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import timber.log.Timber
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class RoomMemberRepository(
    private val roomExpress: RoomExpress,
    private val roomService: RoomService
) : Repository() {

    private val disposables: MutableList<Disposable?> = mutableListOf()
    private val takenSurfaces = arrayListOf<SurfaceIndex>()
    private val roomMembers = MutableLiveData<List<RoomMember>>()

    fun getObservableRoomMembers(): MutableLiveData<List<RoomMember>> {
        roomService.observableActiveRoom.value.observableMembers.subscribe { members ->
            updateMemberList(members)
        }.run { disposables.add(this) }
        return roomMembers
    }

    private fun updateMemberList(members: Array<Member>) = launch {
        launch(Dispatchers.Main) {
            val memberList = ArrayList<RoomMember>()
            takenSurfaces.clear()
            members.forEach { member ->
                val roomMember = member.getFromList(roomMembers.value ?: listOf()) ?: RoomMember(member)
                roomMember.surface = getAvailableSurfaceIndex()
                memberList.add(roomMember)
            }
            roomMembers.value = memberList
        }
    }

    private fun getAvailableSurfaceIndex(): SurfaceIndex {
        var surfaceIndex = SurfaceIndex.SURFACE_NONE
        var found = false
        SurfaceIndex.values().forEach {
            if (!found && it != SurfaceIndex.SURFACE_NONE && !takenSurfaces.contains(it)) {
                takenSurfaces.add(it)
                surfaceIndex = it
                found = true
            }
        }
        return surfaceIndex
    }

    suspend fun subscribeToMemberMedia(roomMember: RoomMember, options: SubscribeToMemberStreamOptions): RoomStatus
            = suspendCoroutine { continuation ->
        val members = roomMembers.value ?: mutableListOf()
        members.firstOrNull { it.member.sessionId == roomMember.member.sessionId }?.let { member ->
            member.member.observableStreams.subscribe { streams ->
                val stream = streams.getOrNull(0)
                if (stream != null && !member.isSubscribed()) {
                    roomExpress.subscribeToMemberStream(stream, options) { status, subscriber, renderer ->
                        var message = ""
                        if (status == RequestStatus.OK) {
                            launch {
                                launch(Dispatchers.Main) {
                                    member.renderer = renderer
                                    member.subscriber = subscriber
                                    if (member.surface == SurfaceIndex.SURFACE_NONE) {
                                        member.surface = getAvailableSurfaceIndex()
                                    }
                                    roomMembers.value = members
                                    Timber.d("Subscribed to member media: $status $member")
                                    continuation.resume(RoomStatus(status, message))
                                }
                            }
                        } else {
                            message = "Failed to subscribe to member media"
                            continuation.resume(RoomStatus(status, message))
                        }
                    }
                } else {
                    Timber.d("Member stream has ended")
                    takenSurfaces.remove(member.surface)
                    member.surface = SurfaceIndex.SURFACE_NONE
                    roomMembers.value = members
                }
            }.run { disposables.add(this) }
        }
    }

    fun dispose() = launch {
        disposables.forEach { it?.dispose() }
        disposables.clear()

        launch(Dispatchers.Main) {
            takenSurfaces.clear()
            roomMembers.value?.forEach {
                try {
                    it.renderer?.stop()
                    it.renderer?.dispose()
                    it.renderer = null
                    it.subscriber?.dispose()
                    it.subscriber = null
                } catch (e: Exception) {
                    Timber.d("Failed to dispose room member: $it")
                }
            }
            roomMembers.value = null
        }
    }

}
