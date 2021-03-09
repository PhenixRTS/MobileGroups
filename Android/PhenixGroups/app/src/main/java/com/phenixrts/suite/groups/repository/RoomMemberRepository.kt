/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import android.os.Handler
import android.os.Looper
import androidx.lifecycle.MutableLiveData
import com.phenixrts.common.Disposable
import com.phenixrts.room.RoomService
import com.phenixrts.suite.groups.common.enums.AudioLevel
import com.phenixrts.suite.groups.common.extensions.call
import com.phenixrts.suite.phenixcommon.common.launchMain
import com.phenixrts.suite.groups.common.extensions.mapRoomMember
import com.phenixrts.suite.groups.models.RoomMember
import com.phenixrts.suite.phenixdeeplink.models.PhenixConfiguration
import timber.log.Timber

private const val MEMBER_PICK_DELAY = 1000 * 2L
private const val MEMBER_RE_PICK_DELAY = 1000 * 5L

class RoomMemberRepository(
    private val roomService: RoomService,
    private val selfMember: RoomMember,
    private val configuration: PhenixConfiguration
) {

    private val disposables: MutableList<Disposable> = mutableListOf()
    private val memberPickerHandler = Handler(Looper.getMainLooper())
    private val memberPickerRunnable = Runnable {
        pickLoudestMember()
    }
    val roomMembers = MutableLiveData<List<RoomMember>>()

    init {
        launchMain {
            observeRoomMembers()
        }
    }

    private fun observeRoomMembers() {
        roomMembers.value = listOf(selfMember)
        clearDisposables()
        roomService.observableActiveRoom.value.observableMembers.subscribe { members ->
            launchMain {
                Timber.d("Received RAW members count: ${members.size}")
                // Map received Members to existing RoomMembers or create new ones in transformation
                val selfId = roomService.self.sessionId
                val memberList = mutableListOf(roomService.self.mapRoomMember(roomMembers.value, selfId))
                val mappedMembers = members.filterNot { it.sessionId == selfId }.mapTo(memberList) {
                    it.mapRoomMember(roomMembers.value, selfId)
                }
                updateMemberList(mappedMembers)
            }
        }.run { disposables.add(this) }
    }

    private fun clearDisposables() {
        disposables.forEach { it.dispose() }
        disposables.clear()
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
            // Allow video render if limit not reached
            if (showingVideoCount < configuration.videoMemberCount && !member.canRenderVideo) {
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
                Timber.d("Deselect active member: ${toString()}")
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
                    .maxByOrNull { it.audioLevel.value?.ordinal ?: AudioLevel.VOLUME_0.ordinal }
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
            Timber.d("Unpin member: ${toString()}")
            onUpdate.call(this)
        }
        // Pin new member
        roomMembers.value?.find { it.isThisMember(roomMember.member.sessionId) }?.run {
            isActiveRenderer = true
            isPinned = !wasPinned
            Timber.d("Pin member: ${toString()}")
            onUpdate.call(this)
        }
        rePickMember(false)
        Timber.d("Changed member pin state: $roomMember")
    }

    fun switchAudioStreamState(enabled: Boolean) {
        roomMembers.value?.find { it.isSelf }?.run {
            if (isAudioEnabled != enabled) {
                Timber.d("Self audio state changed: $enabled $this")
                onUpdate.call(this)
            }
        }
    }

    fun switchVideoStreamState(enabled: Boolean) {
        roomMembers.value?.find { it.isSelf }?.run {
            if (canRenderVideo && isVideoEnabled != enabled) {
                Timber.d("Self video state changed: $enabled $this")
                onUpdate.call(this)
            }
        }
    }

    fun dispose() {
        clearDisposables()
        roomMembers.value?.forEach { it.dispose() }
        roomMembers.postValue(listOf())
    }

}
