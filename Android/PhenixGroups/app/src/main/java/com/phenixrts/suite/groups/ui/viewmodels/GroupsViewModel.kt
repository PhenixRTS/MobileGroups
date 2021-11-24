/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.viewmodels

import android.os.Build
import android.os.Handler
import android.os.Looper
import com.phenixrts.suite.phenixcore.common.ConsumableSharedFlow

import androidx.lifecycle.ViewModel
import com.phenixrts.room.MemberRole
import com.phenixrts.suite.groups.BuildConfig
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.cache.PreferenceProvider
import com.phenixrts.suite.groups.cache.entities.RoomInfoItem
import com.phenixrts.suite.groups.common.extensions.MESSAGE_REFRESH_DELAY
import com.phenixrts.suite.groups.common.extensions.asRoomMessages
import com.phenixrts.suite.groups.common.extensions.expirationDate
import com.phenixrts.suite.groups.models.RoomMessage
import com.phenixrts.suite.phenixcore.PhenixCore
import com.phenixrts.suite.phenixcore.common.launchIO
import com.phenixrts.suite.phenixcore.common.launch
import com.phenixrts.suite.phenixdebugmenu.DebugMenu
import com.phenixrts.suite.phenixcore.repositories.models.PhenixMember
import com.phenixrts.suite.phenixcore.repositories.models.PhenixRoom
import com.phenixrts.suite.phenixcore.repositories.models.PhenixRoomConfiguration
import kotlinx.coroutines.flow.asSharedFlow
import timber.log.Timber
import java.util.*
import kotlin.properties.Delegates

class GroupsViewModel(
    private val cacheProvider: CacheProvider,
    private val preferenceProvider: PreferenceProvider,
    private val phenixCore: PhenixCore
) : ViewModel() {

    private val rawMessages = mutableListOf<RoomMessage>()
    private val _onVideoEnabled = ConsumableSharedFlow<Boolean>(canReplay = true)
    private val _onAudioEnabled = ConsumableSharedFlow<Boolean>(canReplay = true)
    private val _onControlsEnabled = ConsumableSharedFlow<Boolean>(canReplay = true)
    private val _messages = ConsumableSharedFlow<List<RoomMessage>>(canReplay = true)
    private val _members = ConsumableSharedFlow<List<PhenixMember>>(canReplay = true)
    private var isViewingChat = false
    private var currentRoom: PhenixRoom? = null

    private val refreshHandler = Handler(Looper.getMainLooper())
    private val refreshRunnable = Runnable {
        updateMessages()
    }

    val roomList = cacheProvider.cacheDao().getVisitedRooms(phenixCore.configuration?.backend ?: BuildConfig.BACKEND_URL)
    val memberCount = phenixCore.memberCount
    var displayName: String by Delegates.observable(preferenceProvider.displayName ?: Build.MODEL) { _, _, name ->
        preferenceProvider.displayName = name
    }

    val messages = _messages.asSharedFlow()
    val members = _members.asSharedFlow()
    val onVideoEnabled = _onVideoEnabled.asSharedFlow()
    val onAudioEnabled = _onAudioEnabled.asSharedFlow()
    val onControlsEnabled = _onControlsEnabled.asSharedFlow()

    val areControlsEnabled get() = _onControlsEnabled.replayCache.lastOrNull() ?: false
    val isVideoEnabled get() = _onVideoEnabled.replayCache.lastOrNull() ?: false
    val isAudioEnabled get() = _onAudioEnabled.replayCache.lastOrNull() ?: false

    val isInRoom get() = currentRoom != null
    val currentRoomAlias get() = currentRoom?.alias ?: ""

    init {
        Timber.d("View model created")
        expireOldRooms()
        launch {
            phenixCore.rooms.collect { rooms ->
                val room = rooms.firstOrNull()
                currentRoom = room
                Timber.d("Rooms updated: $rooms, $isInRoom")
                if (room != null) {
                    onRoomJoined(room)
                }
            }
        }
        launch {
            phenixCore.messages.collect { messages ->
                members.replayCache.lastOrNull()?.firstOrNull { it.isSelf }?.id?.let { selfId ->
                    rawMessages.clear()
                    rawMessages.addAll(messages.asRoomMessages(selfId, isViewingChat))
                    updateMessages()
                }
            }
        }
        launch {
            phenixCore.members.collect { members ->
                members.firstOrNull { it.isSelf }?.let { self ->
                    _onAudioEnabled.tryEmit(self.isAudioEnabled)
                    _onVideoEnabled.tryEmit(self.isVideoEnabled)
                }
                _members.tryEmit(members)
            }
        }
    }

    fun enableVideo(enabled: Boolean) {
        phenixCore.setSelfVideoEnabled(enabled)
        _onVideoEnabled.tryEmit(enabled)
    }

    fun enableAudio(enabled: Boolean) {
        phenixCore.setSelfAudioEnabled(enabled)
        _onAudioEnabled.tryEmit(enabled)
    }

    fun joinRoom(roomAlias: String? = null, roomId: String? = null) {
        if (roomAlias == null && roomId == null) return
        phenixCore.publishToRoom(PhenixRoomConfiguration(
            roomId = roomId ?: "",
            roomAlias = roomAlias ?: "",
            memberName = displayName,
            memberRole = MemberRole.MODERATOR,
            maxVideoRenderers = phenixCore.configuration?.maxVideoRenderers ?: BuildConfig.MAX_VIDEO_MEMBERS
        ))
    }

    fun sendChatMessage(message: String) {
        Timber.d("Sending message: $message")
        phenixCore.sendMessage(message, "")
    }

    fun switchCameraFacing() = phenixCore.flipCamera()

    fun selectMember(memberId: String, selected: Boolean) {
        members.replayCache.lastOrNull()?.forEach { member ->
            phenixCore.selectMember(member.id, false)
        }
        phenixCore.selectMember(memberId, selected)
    }

    fun leaveRoom() = phenixCore.leaveRoom()

    fun setViewingChat(viewing: Boolean) {
        isViewingChat = viewing
    }

    fun enableControls(enabled: Boolean) {
        Timber.d("Enabling controls: $enabled")
        _onControlsEnabled.tryEmit(enabled)
    }

    fun onConnectionLost() {
        Timber.d("Connection lost")
        leaveRoom()
    }

    fun observeDebugMenu(debugMenu: DebugMenu, onError: () -> Unit, onShow: () -> Unit) {
        debugMenu.observeDebugMenu(
            phenixCore,
            "${BuildConfig.APPLICATION_ID}.provider",
            onError = onError,
            onShow = onShow
        )
    }

    private fun updateMessages() {
        _messages.tryEmit(rawMessages.map { it.copy() })
        refreshHandler.removeCallbacks(refreshRunnable)
        refreshHandler.postDelayed(refreshRunnable, MESSAGE_REFRESH_DELAY)
    }

    private fun expireOldRooms() = launchIO {
        cacheProvider.cacheDao().expireOldRooms(Calendar.getInstance().expirationDate())
    }

    private fun onRoomJoined(room: PhenixRoom) = launchIO {
        cacheProvider.cacheDao().insertRoom(RoomInfoItem(
            alias = room.alias,
            roomId = room.id,
            backendUri = phenixCore.configuration?.backend ?: BuildConfig.BACKEND_URL,
            dateLeft = getRoomDateLeft(room.alias)
        ))
    }

    private fun getRoomDateLeft(roomAlias: String): Date {
        var dateRoomLeft = Date()
        cacheProvider.cacheDao().getVisitedRoom(roomAlias).getOrNull(0)?.let { room ->
            dateRoomLeft = room.dateLeft
        }
        Timber.d("Room with alias: $roomAlias left at: $dateRoomLeft")
        return dateRoomLeft
    }

}
