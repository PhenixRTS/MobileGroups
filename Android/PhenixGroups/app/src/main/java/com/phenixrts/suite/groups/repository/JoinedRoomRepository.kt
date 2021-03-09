/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import androidx.lifecycle.MutableLiveData
import com.phenixrts.chat.RoomChatService
import com.phenixrts.common.Disposable
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.ExpressPublisher
import com.phenixrts.room.RoomService
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.common.extensions.*
import com.phenixrts.suite.groups.models.RoomMessage
import com.phenixrts.suite.groups.models.RoomStatus
import com.phenixrts.suite.phenixcommon.common.launchIO
import com.phenixrts.suite.phenixcommon.common.launchMain
import timber.log.Timber
import java.util.*
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class JoinedRoomRepository(
    private val roomService: RoomService,
    private val chatService: RoomChatService,
    private val publisher: ExpressPublisher,
    private val dateRoomLeft: Date
) {

    private val disposables: MutableList<Disposable> = mutableListOf()
    private var isViewingChat = false
    val chatMessages = MutableLiveData<List<RoomMessage>>()

    init {
        launchMain {
            observeChatMessages()
        }
    }

    private fun dispose() {
        launchMain {
            chatMessages.value = mutableListOf()
        }
        clearDisposables()
        roomService.dispose()
        chatService.dispose()
        publisher.dispose()
        Timber.d("Joined room disposed")
    }

    private fun observeChatMessages() {
        clearDisposables()
        chatService.observableChatMessages.subscribe { messages ->
            Timber.d("Message list updated ${messages.size}")
            launchMain {
                val history = chatMessages.value?.toMutableList() ?: mutableListOf()
                history.addUnique(messages, roomService.self.observableScreenName.value, dateRoomLeft, isViewingChat)
                chatMessages.value = history
            }
        }.run { disposables.add(this) }
    }

    fun clearDisposables() {
        disposables.forEach { it.dispose() }
        disposables.clear()
    }

    fun setViewingChat(viewingChat: Boolean) {
        isViewingChat = viewingChat
        if (viewingChat) {
            chatMessages.value?.filter { !it.isRead }?.takeIf { it.isNotEmpty() }?.let { messages ->
                messages.forEach { it.isRead = true }
                chatMessages.refresh()
            }
        }
    }

    fun sendChatMessage(message: String, continuation: Continuation<RoomStatus>) {
        Timber.d("Sending message: $message")
        chatService.sendMessageToRoom(message) { status, errorMessage ->
            if (status == RequestStatus.OK) {
                Timber.d("Message sent: $message $chatService")
                continuation.resume(RoomStatus(status))
            } else {
                Timber.w("Message is not sent: $errorMessage")
                continuation.resume(RoomStatus(status, errorMessage))
            }
        }
    }

    fun switchVideoStreamState(enabled: Boolean) = launchIO {
        if (publisher.hasEnded()) return@launchIO
        Timber.d("Switching publisher video streams: $enabled")
        if (enabled) {
            publisher.enableVideo()
        } else {
            publisher.disableVideo()
        }
    }

    fun switchAudioStreamState(enabled: Boolean) = launchIO {
        if (publisher.hasEnded()) return@launchIO
        Timber.d("Switching publisher audio streams: $enabled")
        if (enabled) {
            publisher.enableAudio()
        } else {
            publisher.disableAudio()
        }
    }

    suspend fun leaveRoom(cacheProvider: CacheProvider) = suspendCoroutine<Unit> { continuation ->
        launchIO {
            val roomId = roomService.observableActiveRoom.value.roomId
            cacheProvider.cacheDao().updateRoomLeftDate(roomId, Date())
            publisher.stop()
            roomService.leaveRoom { _, status ->
                Timber.d("Room left: $status $roomId")
                continuation.resume(Unit)
            }
            dispose()
        }
    }

}
