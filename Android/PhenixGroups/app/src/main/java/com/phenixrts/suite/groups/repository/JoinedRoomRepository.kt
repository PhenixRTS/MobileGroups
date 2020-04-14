/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import androidx.lifecycle.MutableLiveData
import com.phenixrts.chat.RoomChatServiceFactory
import com.phenixrts.common.Disposable
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.ExpressPublisher
import com.phenixrts.room.RoomService
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.common.extensions.addUnique
import com.phenixrts.suite.groups.common.extensions.launchIO
import com.phenixrts.suite.groups.common.extensions.launchMain
import com.phenixrts.suite.groups.models.RoomMessage
import com.phenixrts.suite.groups.models.RoomStatus
import timber.log.Timber
import java.util.*
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume

class JoinedRoomRepository(
    private val roomService: RoomService,
    private val publisher: ExpressPublisher
) {

    private val chatService = RoomChatServiceFactory.createRoomChatService(roomService)
    private val disposables: MutableList<Disposable?> = mutableListOf()
    private val chatHistory = MutableLiveData<List<RoomMessage>>()

    private fun dispose() = launchIO {
        launchMain {
            chatHistory.value = mutableListOf()
        }

        disposables.forEach { it?.dispose() }
        disposables.clear()

        roomService.dispose()
        chatService.dispose()
        publisher.dispose()
        Timber.d("Joined room disposed")
    }

    fun getObservableChatMessages(): MutableLiveData<List<RoomMessage>> {
        chatService.observableChatMessages.subscribe { messages ->
            Timber.d("Message list updated ${messages.size}")
            launchMain {
                Timber.d("Message list updated")
                val history = chatHistory.value?.toMutableList() ?: mutableListOf()
                history.addUnique(messages, roomService.self.observableScreenName.value)
                chatHistory.value = history
            }
        }.run { disposables.add(this) }
        return chatHistory
    }

    fun sendChatMessage(message: String, continuation: Continuation<RoomStatus>) {
        Timber.d("Sending message: $message")
        chatService?.sendMessageToRoom(message) { status, errorMessage ->
            if (status == RequestStatus.OK) {
                Timber.d("Message sent: $message $chatService")
                continuation.resume(RoomStatus(status))
            } else {
                Timber.w("Message is not sent: $errorMessage")
                continuation.resume(RoomStatus(status, errorMessage))
            }
        } ?: continuation.resume(RoomStatus(RequestStatus.NOT_INITIALIZED, "Chat Service is not initialized"))
    }

    fun switchVideoStreamState(enabled: Boolean) = launchIO {
        Timber.d("Switching publisher video streams: $enabled")
        if (enabled) {
            publisher.enableVideo()
        } else {
            publisher.disableVideo()
        }
    }

    fun switchAudioStreamState(enabled: Boolean) = launchIO {
        Timber.d("Switching publisher audio streams: $enabled")
        if (enabled) {
            publisher.enableAudio()
        } else {
            publisher.disableAudio()
        }
    }

    fun leaveRoom(cacheProvider: CacheProvider) = launchIO {
        val roomId = roomService.observableActiveRoom.value.roomId
        cacheProvider.cacheDao().updateRoomLeftDate(roomId, Date())
        publisher.stop()
        roomService.leaveRoom { _, status ->
            Timber.d("Room left: $status $roomId")
        }
        dispose()
    }

}
