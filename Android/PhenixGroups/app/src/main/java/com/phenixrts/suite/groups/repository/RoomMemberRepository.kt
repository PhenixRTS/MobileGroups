/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import androidx.lifecycle.MutableLiveData
import com.phenixrts.common.Disposable
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.RoomExpress
import com.phenixrts.express.SubscribeToMemberStreamOptions
import com.phenixrts.room.RoomService
import com.phenixrts.room.TrackState
import com.phenixrts.suite.groups.BuildConfig
import com.phenixrts.suite.groups.common.extensions.call
import com.phenixrts.suite.groups.common.extensions.mapRoomMember
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
            Timber.d("Received RAW members count: ${members.size}")
            // Map received Members to existing RoomMembers or create new ones in transformation
            val selfId = roomService.self.sessionId
            val memberList = mutableListOf(roomService.self.mapRoomMember(roomMembers.value, selfId))
            val mappedMembers = members.filterNot { it.sessionId == selfId }.mapTo(memberList) {
                it.mapRoomMember(roomMembers.value, selfId)
            }
            updateMemberList(mappedMembers)
        }.run { disposables.add(this) }
        return roomMembers
    }

    private fun updateMemberList(members: List<RoomMember>) = launch {
        launch(Dispatchers.Main) {
            disposeGoneMembers(members)
            enableMemberRenderers(members)
            pickActiveRenderer(members)
            Timber.d("Updated members list: $members")
            roomMembers.value = members
        }
    }

    private fun disposeGoneMembers(members: List<RoomMember>) {
        roomMembers.value?.forEach { member ->
            member.takeIf { !member.isSelf && members.find { it.isThisMember(member.member.sessionId) } == null }?.let {
                Timber.d("Disposing gone member: $it")
                it.dispose()
            }
        }
    }

    private fun enableMemberRenderers(members: List<RoomMember>) {
        var showingVideoCount = members.count { it.canRenderVideo }
        members.forEach { member ->
            val memberStream = member.member.observableStreams.value?.get(0)
            val videoEnabled = memberStream?.observableVideoState?.value == TrackState.ENABLED
            val audioMuted = memberStream?.observableAudioState?.value != TrackState.ENABLED
            member.canShowPreview = videoEnabled
            member.isMuted = audioMuted

            // Allow video render if limit not reached
            if (showingVideoCount < BuildConfig.MAX_RENDERERS && !member.canRenderVideo) {
                member.canRenderVideo = true
                showingVideoCount++
            }
        }
    }

    private fun pickActiveRenderer(members: List<RoomMember>) {
        if (members.find { it.isPinned } == null) {
            // Deselect current active renderer
            members.find { it.isActiveRenderer }?.run {
                isActiveRenderer = false
                onUpdate.call(this)
            }

            // Pick anyone who can render video but self if available
            members.findLast { it.canRenderVideo && !it.isSelf }?.run {
                if (!isActiveRenderer) {
                    isActiveRenderer = true
                    Timber.d("Picked active renderer: ${toString()}")
                    onUpdate.call(this)
                }
            } ?: members.findLast { it.canRenderVideo }?.run {
                if (!isActiveRenderer) {
                    isActiveRenderer = true
                    Timber.d("Picked active renderer: ${toString()}")
                    onUpdate.call(this)
                }
            }
        }
    }

    fun pinActiveMember(roomMember: RoomMember) {
        val wasPinned = roomMember.isPinned
        // Unpin current member
        roomMembers.value?.find { it.isActiveRenderer }?.run {
            isPinned = false
            isActiveRenderer = false
            onUpdate.call(this)
        }
        // Pin new member
        roomMembers.value?.find { it.isThisMember(roomMember.member.sessionId) }?.run {
            isActiveRenderer = true
            isPinned = !wasPinned
            onUpdate.call(this)
        }
        Timber.d("Changed member pin state: $roomMember")
    }

    fun switchAudioStreamState(enabled: Boolean) {
        roomMembers.value?.find { it.isSelf }?.run {
            if (isMuted == enabled) {
                isMuted = !enabled
                Timber.d("Self audio state changed: $enabled $this")
                onUpdate.call(this)
            }
        }
    }

    fun switchVideoStreamState(enabled: Boolean) {
        roomMembers.value?.find { it.isSelf }?.run {
            if (canRenderVideo && canShowPreview != enabled) {
                canShowPreview = enabled
                Timber.d("Self video state changed: $enabled $this")
                onUpdate.call(this)
            }
        }
    }

    suspend fun subscribeToMemberMedia(roomMember: RoomMember, options: SubscribeToMemberStreamOptions): RoomStatus
            = suspendCoroutine { continuation ->
        val members = roomMembers.value ?: mutableListOf()
        members.find { it.isThisMember(roomMember.member.sessionId) }?.let { member ->
            member.member.observableStreams.subscribe { streams ->
                val stream = streams.getOrNull(0)
                if (stream != null && !member.isSubscribed()) {
                    roomExpress.subscribeToMemberStream(stream, options) { status, subscriber, renderer ->
                        launch {
                            launch(Dispatchers.Main) {
                                var message = ""
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
