/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.phenix

import androidx.lifecycle.MutableLiveData
import com.phenixrts.chat.RoomChatService
import com.phenixrts.chat.RoomChatServiceFactory
import com.phenixrts.common.Disposable
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.JoinRoomOptions
import com.phenixrts.express.RoomExpress
import com.phenixrts.express.RoomExpressFactory
import com.phenixrts.room.RoomService
import com.phenixrts.room.RoomServiceFactory
import com.phenixrts.room.RoomType
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.common.getRoomCode
import com.phenixrts.suite.groups.cache.entities.RoomInfoItem
import com.phenixrts.suite.groups.common.extensions.asChatMessageItems
import com.phenixrts.suite.groups.models.RoomStatus
import kotlinx.coroutines.*
import timber.log.Timber
import java.util.*
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class RoomExpressRepository(
    private val cacheProvider: CacheProvider,
    private val roomExpress: RoomExpress,
    val roomStatus: MutableLiveData<RoomStatus>
) {

    /**
     * The scope on which to run executables
     */
    private val repositoryScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private val disposables: MutableList<Disposable?> = mutableListOf()

    // TODO: If there is a case where multiple of these can live simultaneously - extract them to separate repositories
    private var roomService: RoomService? = null
    private var chatService: RoomChatService? = null

    fun getCurrentRoomId(): String = roomService?.observableActiveRoom?.value?.roomId ?: ""

    /**
     * Launch a suspendable function in phenix repository scope on IO thread
     */
    fun launch(block: suspend CoroutineScope.() -> Unit) = repositoryScope.launch(
        context = CoroutineExceptionHandler { _, e ->
            Timber.w("Coroutine failed: ${e.localizedMessage}")
            e.printStackTrace()
        },
        block = block
    )

    /**
     * Wait unit PCast is online to continue
     */
    suspend fun waitForPCast(): Unit = suspendCoroutine {
        roomExpress.pCastExpress.waitForOnline {
            it.resume(Unit)
        }
    }

    /**
     * Create a new meeting room and block until executed
     */
    suspend fun createRoom(): RoomStatus = suspendCoroutine {
        val code = getRoomCode()
        val options = RoomServiceFactory.createRoomOptionsBuilder()
            .withName(code)
            .withAlias(code)
            .withType(RoomType.MULTI_PARTY_CHAT)
            .buildRoomOptions()

        roomExpress.createRoom(options) { status, room ->
            launch {
                Timber.d("Room create completed with status: $status")
                it.resume(RoomStatus(status, room.roomId))
            }
        }
    }

    /**
     * Join a room with given room ID and user screen name
     */
    suspend fun joinRoomById(id: String, userScreenName: String): RequestStatus = suspendCoroutine { continuation ->
        val joinRoomOptions = RoomExpressFactory.createJoinRoomOptionsBuilder()
            .withRoomId(id)
            .withScreenName(userScreenName)
            .buildJoinRoomOptions()
        joinRoom(joinRoomOptions, continuation)
    }

    /**
     * Join a room with given room alias and user screen name
     */
    suspend fun joinRoomByAlias(roomAlias: String, userScreenName: String): RequestStatus = suspendCoroutine { continuation ->
        val joinRoomOptions = RoomExpressFactory.createJoinRoomOptionsBuilder()
            .withRoomAlias(roomAlias)
            .withScreenName(userScreenName)
            .buildJoinRoomOptions()
        joinRoom(joinRoomOptions, continuation)
    }

    /**
     * Try to join a room with given room options and block until executed
     */
    private fun joinRoom(joinRoomOptions: JoinRoomOptions, continuation: Continuation<RequestStatus>) {
        roomExpress.joinRoom(joinRoomOptions) { status, roomService ->
            Timber.d("Room join completed with status: $status")
            if (status == RequestStatus.OK) {
                this.roomService = roomService
                val room = roomService.observableActiveRoom.value
                cacheProvider.cacheDao().insertRoom(RoomInfoItem(room.roomId, room.observableAlias.value))
                observeChat()
            }
            continuation.resume(status)
        }
    }

    /**
     * Start observing chat messages for current room
     */
    private fun observeChat() {
        chatService = RoomChatServiceFactory.createRoomChatService(roomService)
        chatService?.observableChatMessages?.subscribe { messages ->
            Timber.d("Message list updated ${messages.size} ${getCurrentRoomId()}")
            cacheProvider.cacheDao().insertChatMessages(messages.asChatMessageItems(getCurrentRoomId()))
        }.run { disposables.add(this) }
    }

    // TODO: Ignore this for Milestone 1 - this will be implemented later
    fun getRoomMembers() {
        Timber.d("Subscribing to Members events")
        roomService?.observableActiveRoom?.value?.observableMembers?.subscribe {
            Timber.d("Room member event")
        }
    }

    /**
     * Used to send a chat message
     */
    suspend fun sendChatMessage(message: String): RoomStatus = suspendCoroutine {
        Timber.d("Sending message: $message")
        chatService?.sendMessageToRoom(message) { status, errorMessage ->
            if (status == RequestStatus.OK) {
                Timber.d("Message sent: $message $chatService")
                it.resume(RoomStatus(status))
            } else {
                Timber.w("Message is not sent: $errorMessage")
                it.resume(RoomStatus(status, errorMessage))
            }
        } ?: it.resume(RoomStatus(RequestStatus.NOT_INITIALIZED, "Chat Service is not initialized"))
    }

    /**
     * Used to leave current active room
     */
    suspend fun leaveRoom(): RequestStatus = suspendCoroutine{ continuation ->
        roomService?.observableActiveRoom?.value?.roomId?.let {
            cacheProvider.cacheDao().updateRoomLeftDate(it, Date())
        }
        disposables.forEach { it?.dispose() }
        disposables.clear()

        roomService?.leaveRoom { _, status ->
            Timber.d("Room left")
            continuation.resume(status)
        } ?: continuation.resume(RequestStatus.NOT_INITIALIZED)

        roomService?.dispose()
        chatService?.dispose()
        roomService = null
        chatService = null
    }
}
