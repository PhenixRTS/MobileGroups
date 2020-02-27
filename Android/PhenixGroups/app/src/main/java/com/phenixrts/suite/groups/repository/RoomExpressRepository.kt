/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import androidx.lifecycle.MutableLiveData
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.*
import com.phenixrts.pcast.UserMediaStream
import com.phenixrts.room.RoomService
import com.phenixrts.room.RoomServiceFactory
import com.phenixrts.room.RoomType
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.common.getRoomCode
import com.phenixrts.suite.groups.cache.entities.RoomInfoItem
import com.phenixrts.suite.groups.models.JoinedRoomStatus
import com.phenixrts.suite.groups.models.RoomStatus
import timber.log.Timber
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class RoomExpressRepository(
    private val cacheProvider: CacheProvider,
    val roomExpress: RoomExpress,
    val roomStatus: MutableLiveData<RoomStatus>
) : Repository() {

    /**
     * Try to join a room with given room options and block until executed
     */
    private fun joinRoom(publishToRoomOptions: PublishToRoomOptions, continuation: Continuation<JoinedRoomStatus>) {
        roomExpress.publishToRoom(publishToRoomOptions) { status: RequestStatus, roomService: RoomService?, publisher: ExpressPublisher ->
            Timber.d("Room join completed with status: $status")
            if (status == RequestStatus.OK && roomService != null) {
                val room = roomService.observableActiveRoom.value
                cacheProvider.cacheDao().insertRoom(RoomInfoItem(room.roomId, room.observableAlias.value))
            }
            continuation.resume(JoinedRoomStatus(status, roomService))
        }
    }

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
    suspend fun joinRoomById(roomId: String, userScreenName: String,
                             userMediaStream: UserMediaStream): JoinedRoomStatus = suspendCoroutine { continuation ->
        val publishOptions = PCastExpressFactory.createPublishOptionsBuilder()
            .withUserMedia(userMediaStream)
            .buildPublishOptions()
        val publishToRoomOptions = RoomExpressFactory.createPublishToRoomOptionsBuilder()
            .withRoomId(roomId)
            .withPublishOptions(publishOptions)
            .withScreenName(userScreenName)
            .buildPublishToRoomOptions()
        joinRoom(publishToRoomOptions, continuation)
    }

    /**
     * Join a room with given room alias and user screen name
     */
    suspend fun joinRoomByAlias(roomAlias: String, userScreenName: String,
                                userMediaStream: UserMediaStream): JoinedRoomStatus = suspendCoroutine { continuation ->
        val roomOptions = RoomServiceFactory.createRoomOptionsBuilder()
            .withAlias(roomAlias)
            .withName(roomAlias)
            .withType(RoomType.MULTI_PARTY_CHAT)
            .buildRoomOptions()
        val publishOptions = PCastExpressFactory.createPublishOptionsBuilder()
            .withUserMedia(userMediaStream)
            .buildPublishOptions()
        val publishToRoomOptions = RoomExpressFactory.createPublishToRoomOptionsBuilder()
            .withRoomOptions(roomOptions)
            .withPublishOptions(publishOptions)
            .withScreenName(userScreenName)
            .buildPublishToRoomOptions()
        joinRoom(publishToRoomOptions, continuation)
    }

}
