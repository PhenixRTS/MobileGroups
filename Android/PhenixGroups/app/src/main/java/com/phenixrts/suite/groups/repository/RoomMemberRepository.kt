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
import com.phenixrts.room.TrackState
import com.phenixrts.suite.groups.BuildConfig
import com.phenixrts.suite.groups.common.extensions.call
import com.phenixrts.suite.groups.common.extensions.getRoomMember
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
    private val roomMembers = MutableLiveData<List<RoomMember>>()

    fun getObservableRoomMembers(): MutableLiveData<List<RoomMember>> {
        roomService.observableActiveRoom.value.observableMembers.subscribe { members ->
            updateMemberList(members)
        }.run { disposables.add(this) }
        return roomMembers
    }

    private fun updateMemberList(members: Array<Member>) = launch {
        debounce()
        launch(Dispatchers.Main) {
            val memberList = ArrayList<RoomMember>()
            var showingVideoCount = 0
            var isSomeonePinned = false
            // Map received members with existing ones and count rendering streams
            members.forEach { member ->
                val roomMember = member.getRoomMember(roomMembers.value ?: listOf())
                memberList.add(roomMember)
                if (roomMember.canRenderVideo) {
                    showingVideoCount++
                }
                if (roomMember.isPinned) {
                    isSomeonePinned = true
                }
            }
            // Update member video and audio states
            memberList.forEach {
                val memberStream = it.member.observableStreams.value?.get(0)
                val videoEnabled = memberStream?.observableVideoState?.value == TrackState.ENABLED
                val audioMuted = memberStream?.observableAudioState?.value != TrackState.ENABLED
                Timber.d("Allowing video render: $it $videoEnabled")
                if (showingVideoCount < BuildConfig.MAX_RENDERERS && !it.canRenderVideo) {
                    it.canRenderVideo = true
                    showingVideoCount++
                }
                it.canShowPreview = videoEnabled
                it.isMuted = audioMuted
            }
            // Update active renderer if no member is pinned
            if (!isSomeonePinned) {
                memberList.firstOrNull { it.isActiveRenderer }?.run {
                    if (isActiveRenderer) {
                        isActiveRenderer = false
                        onUpdate.call()
                    }
                }
                // Pick anyone who can render video but self if available
                memberList.lastOrNull { it.canRenderVideo && it.member.sessionId != roomService.self.sessionId }?.run {
                    if (!isActiveRenderer) {
                        isActiveRenderer = true
                        onUpdate.call()
                    }
                } ?: memberList.lastOrNull { it.canRenderVideo }?.run {
                    if (!isActiveRenderer) {
                        isActiveRenderer = true
                        onUpdate.call()
                    }
                }
            }
            // Move self member to top
            memberList.sortByDescending { it.member.sessionId == roomService.self.sessionId }
            Timber.d("Updating members list: $memberList")
            roomMembers.value = memberList
        }
    }

    fun pinActiveMember(roomMember: RoomMember) {
        val wasPinned = roomMember.isPinned
        val members = roomMembers.value ?: mutableListOf()
        var restartRenderer = false

        // Unpin current member
        members.firstOrNull { it.isActiveRenderer }?.run {
            isPinned = false
            isActiveRenderer = false
            restartRenderer = member.sessionId != roomMember.member.sessionId
            onUpdate.call(member.sessionId != roomMember.member.sessionId)
        }
        // Pin new member
        members.firstOrNull { it.member.sessionId == roomMember.member.sessionId }?.run {
            isActiveRenderer = true
            isPinned = !wasPinned
            onUpdate.call(restartRenderer)
        }
        Timber.d("Changed member pin state: $roomMember restartRenderer: $restartRenderer")
    }

    fun switchAudioStreamState(enabled: Boolean) {
        roomMembers.value?.firstOrNull { it.member.sessionId == roomService.self.sessionId }?.run {
            if (isMuted == enabled) {
                Timber.d("Self audio state changed: $enabled $this")
                isMuted = !enabled
                onUpdate.call(false)
            }
        }
    }

    fun switchVideoStreamState(enabled: Boolean) {
        roomMembers.value?.firstOrNull { it.member.sessionId == roomService.self.sessionId }?.run {
            if (canRenderVideo && canShowPreview != enabled) {
                Timber.d("Self video state changed: $enabled $this")
                canShowPreview = enabled
                onUpdate.call()
            }
        }
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
                        launch {
                            launch(Dispatchers.Main) {
                                if (status == RequestStatus.OK) {
                                    member.onSubscribed(subscriber, renderer)
                                    Timber.d("Subscribed to member media: $status $member")
                                    continuation.resume(RoomStatus(status, message))
                                } else {
                                    message = "Failed to subscribe to member media"
                                    member.canShowPreview = false
                                    continuation.resume(RoomStatus(status, message))
                                }
                            }
                        }
                    }
                }
            }.run { disposables.add(this) }
        }
    }

    fun dispose() = launch {
        disposables.forEach { it?.dispose() }
        disposables.clear()

        launch(Dispatchers.Main) {
            roomMembers.value?.forEach { it.dispose() }
            roomMembers.value = null
        }
    }

}
