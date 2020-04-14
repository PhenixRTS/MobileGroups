/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import android.os.Handler
import androidx.lifecycle.MutableLiveData
import com.phenixrts.common.Disposable
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.RoomExpress
import com.phenixrts.express.SubscribeToMemberStreamOptions
import com.phenixrts.room.RoomService
import com.phenixrts.room.TrackState
import com.phenixrts.suite.groups.BuildConfig
import com.phenixrts.suite.groups.common.enums.AudioLevel
import com.phenixrts.suite.groups.common.extensions.call
import com.phenixrts.suite.groups.common.extensions.launchIO
import com.phenixrts.suite.groups.common.extensions.launchMain
import com.phenixrts.suite.groups.common.extensions.mapRoomMember
import com.phenixrts.suite.groups.models.RoomStatus
import com.phenixrts.suite.groups.models.RoomMember
import timber.log.Timber
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class RoomMemberRepository(
    private val roomExpress: RoomExpress,
    private val roomService: RoomService,
    private val selfMember: RoomMember
) {

    private val disposables: MutableList<Disposable?> = mutableListOf()
    private val roomMembers = MutableLiveData<List<RoomMember>>()


    private val memberPickerHandler = Handler()
    private val memberPickerRunnable = Runnable {
        pickLoudestMember()
    }

    init {
        launchMain {
            roomMembers.value = listOf(selfMember)
        }
    }

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

    private fun updateMemberList(members: List<RoomMember>) = launchMain {
        disposeGoneMembers(members)
        enableMemberRenderers(members)
        pickActiveRenderer(members)
        Timber.d("Updated members list: $members")
        roomMembers.value = members
        rePickMember(true)
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

    private fun pickLoudestMember() {
        var loudestPicked = false
        roomMembers.value?.let { members ->
            if (members.find { it.isPinned } == null) {
                members
                    .filter { !it.isSelf && it.canRenderVideo }
                    .maxBy { it.audioLevel.value?.ordinal ?: AudioLevel.VOLUME_0.ordinal }
                    ?.run {
                        // Update if not active already
                        if (!isActiveRenderer) {
                            // Deselect active member
                            members.find { it.isActiveRenderer }?.run {
                                Timber.d("Deselected active renderer: ${toString()}")
                                isActiveRenderer = false
                                onUpdate.call(this)
                            }
                            isActiveRenderer = true
                            onUpdate.call(this)
                            Timber.d("Picked loudest renderer: ${toString()}")
                            loudestPicked = true
                        }
                    }
            }
        }
        rePickMember(loudestPicked)
    }

    private fun rePickMember(justPicked: Boolean) {
        memberPickerHandler.removeCallbacks(memberPickerRunnable)
        memberPickerHandler.postDelayed(memberPickerRunnable, if (justPicked) MEMBER_RE_PICK_DELAY else MEMBER_PICK_DELAY)
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
        rePickMember(false)
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
                        launchMain {
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
            }.run { disposables.add(this) }
        }
    }

    fun dispose() = launchIO {
        disposables.forEach { it?.dispose() }
        disposables.clear()

        launchMain{
            roomMembers.value?.forEach { it.dispose() }
            roomMembers.value = null
        }
    }

    private companion object {
        private const val MEMBER_PICK_DELAY = 1000 * 2L
        private const val MEMBER_RE_PICK_DELAY = 1000 * 5L
    }

}
