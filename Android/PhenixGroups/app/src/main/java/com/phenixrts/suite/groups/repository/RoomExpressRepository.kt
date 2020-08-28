/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import androidx.lifecycle.MutableLiveData
import com.phenixrts.chat.RoomChatService
import com.phenixrts.chat.RoomChatServiceFactory
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.*
import com.phenixrts.pcast.UserMediaStream
import com.phenixrts.room.RoomService
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.common.getRoomCode
import com.phenixrts.suite.groups.cache.entities.RoomInfoItem
import com.phenixrts.suite.groups.common.extensions.CHAT_SUBSCRIPTION_DELAY
import com.phenixrts.suite.groups.common.getPublishOptions
import com.phenixrts.suite.groups.common.getPublishToRoomOptions
import com.phenixrts.suite.groups.common.getRoomOptions
import com.phenixrts.suite.groups.models.RoomExpressConfiguration
import com.phenixrts.suite.groups.models.RoomStatus
import com.phenixrts.suite.phenixcommon.common.launchIO
import com.phenixrts.suite.phenixcommon.common.launchMain
import kotlinx.coroutines.delay
import timber.log.Timber
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class RoomExpressRepository(
    private val cacheProvider: CacheProvider,
    private val roomExpress: RoomExpress,
    private val configuration: RoomExpressConfiguration
) {

    private var isDisposed = false
    var roomService: RoomService? = null
    var expressPublisher: ExpressPublisher? = null
    var chatService: RoomChatService? = null
    val onRoomJoined = MutableLiveData<RequestStatus>()

    /**
     * Try to join a room with given room options and block until executed
     */
    private fun joinRoom(publishToRoomOptions: PublishToRoomOptions) = launchIO {
        roomExpress.publishToRoom(publishToRoomOptions) { status: RequestStatus, service: RoomService?, publisher: ExpressPublisher? ->
            launchMain {
                roomService = service
                expressPublisher = publisher
                if (chatService == null) {
                    delay(CHAT_SUBSCRIPTION_DELAY)
                    chatService = RoomChatServiceFactory.createRoomChatService(roomService)
                }
                var requestStatus = status
                if (status == RequestStatus.OK) {
                    service?.observableActiveRoom?.value?.let { room ->
                        launchIO {
                            cacheProvider.cacheDao().insertRoom(
                                RoomInfoItem(
                                    room.roomId,
                                    room.observableAlias.value,
                                    configuration.backend
                                )
                            )
                        }
                    }
                }
                if (service == null || publisher == null) {
                    requestStatus = RequestStatus.FAILED
                }
                Timber.d("Room join completed with status: $status")
                onRoomJoined.value = requestStatus
            }
        }
    }

    /**
     * Wait unit PCast is online to continue
     */
    suspend fun waitForPCast(): Unit = suspendCoroutine { continuation ->
        if (!isDisposed) {
            roomExpress.pCastExpress.waitForOnline {
                continuation.resume(Unit)
            }
        } else {
            continuation.resume(Unit)
        }
    }

    /**
     * Create a new meeting room and block until executed
     */
    suspend fun createRoom(): RoomStatus = suspendCoroutine {
        val code = getRoomCode()
        val options = getRoomOptions(code)
        roomExpress.createRoom(options) { status, room ->
            launchIO {
                Timber.d("Room create completed with status: $status")
                it.resume(RoomStatus(status, room.roomId))
            }
        }
    }

    /**
     * Join a room with given room ID and user screen name
     */
    fun joinRoomById(roomId: String, userScreenName: String, userMediaStream: UserMediaStream) {
        val publishOptions = getPublishOptions(userMediaStream)
        val publishToRoomOptions = getPublishToRoomOptions(roomId, userScreenName, publishOptions)
        joinRoom(publishToRoomOptions)
    }

    /**
     * Join a room with given room alias and user screen name
     */
    fun joinRoomByAlias(roomAlias: String, userScreenName: String, userMediaStream: UserMediaStream) {
        val roomOptions = getRoomOptions(roomAlias)
        val publishOptions = getPublishOptions(userMediaStream)
        val publishToRoomOptions = getPublishToRoomOptions(userScreenName, roomOptions, publishOptions)
        joinRoom(publishToRoomOptions)
    }

    fun leaveRoom() {
        chatService = null
        roomService = null
        expressPublisher = null
        Timber.d("Room left")
    }

    fun dispose() {
        isDisposed = true
        Timber.d("Room express repository disposed")
    }

}
