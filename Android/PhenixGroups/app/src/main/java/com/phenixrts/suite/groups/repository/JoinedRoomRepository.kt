/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import androidx.lifecycle.MutableLiveData
import com.phenixrts.chat.ChatMessage
import com.phenixrts.chat.RoomChatServiceFactory
import com.phenixrts.common.Disposable
import com.phenixrts.common.RequestStatus
import com.phenixrts.room.RoomService
import com.phenixrts.suite.groups.common.extensions.addUnique
import com.phenixrts.suite.groups.models.RoomStatus
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import timber.log.Timber
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume

class JoinedRoomRepository(private val roomService: RoomService) {

    private val chatService = RoomChatServiceFactory.createRoomChatService(roomService)
    private val disposables: MutableList<Disposable?> = mutableListOf()

    fun getObservableChatMessages(): MutableLiveData<List<ChatMessage>> {
        val chatHistory = MutableLiveData<List<ChatMessage>>()
        chatService.observableChatMessages.subscribe { messages ->
            Timber.d("Message list updated ${messages.size}")
            runBlocking {
                launch(Dispatchers.Main) {
                    Timber.d("Message list updated")
                    val history = chatHistory.value?.toMutableList() ?: mutableListOf()
                    history.addUnique(messages)
                    chatHistory.value = history
                }
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

    fun leaveRoom(): String {
        val roomId = roomService.observableActiveRoom.value.roomId
        roomService.leaveRoom { _, status ->
            Timber.d("Room left")
        }
        clear()
        return roomId
    }

    // TODO: Ignore this for now
    fun getRoomMembers() {
        Timber.d("Subscribing to Members events")
        roomService.observableActiveRoom.value.observableMembers.subscribe {
            Timber.d("Room member event")
        }
    }

    private fun clear() {
        disposables.forEach { it?.dispose() }
        disposables.clear()

        roomService.dispose()
        chatService.dispose()
    }
}
