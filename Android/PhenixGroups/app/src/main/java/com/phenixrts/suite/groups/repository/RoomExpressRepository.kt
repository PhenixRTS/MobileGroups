/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import androidx.lifecycle.MutableLiveData
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.*
import com.phenixrts.pcast.UserMediaStream
import com.phenixrts.room.RoomService
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.common.getRoomCode
import com.phenixrts.suite.groups.cache.entities.RoomInfoItem
import com.phenixrts.suite.groups.common.getPublishOptions
import com.phenixrts.suite.groups.common.getPublishToRoomOptions
import com.phenixrts.suite.groups.common.getRoomOptions
import com.phenixrts.suite.groups.models.JoinedRoomStatus
import com.phenixrts.suite.groups.models.RoomStatus
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.suspendCancellableCoroutine
import timber.log.Timber
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
    private fun joinRoom(publishToRoomOptions: PublishToRoomOptions,
                         continuation: CancellableContinuation<JoinedRoomStatus>) = launch {
        roomExpress.publishToRoom(publishToRoomOptions) { status: RequestStatus, roomService: RoomService?,
                                                          publisher: ExpressPublisher? ->
            Timber.d("Room join completed with status: $status")
            var requestStatus = status
            if (status == RequestStatus.OK) {
                roomService?.observableActiveRoom?.value?.let { room ->
                    cacheProvider.cacheDao().insertRoom(RoomInfoItem(room.roomId, room.observableAlias.value))
                }
            }
            if (roomService == null || publisher == null) {
                requestStatus = RequestStatus.FAILED
            }
            if (continuation.isActive) {
                continuation.resume(JoinedRoomStatus(requestStatus, roomService, publisher))
            }
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
        val options = getRoomOptions(code)
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
                             userMediaStream: UserMediaStream): JoinedRoomStatus = suspendCancellableCoroutine { continuation ->
        val publishOptions = getPublishOptions(userMediaStream)
        val publishToRoomOptions = getPublishToRoomOptions(roomId, userScreenName, publishOptions)
        joinRoom(publishToRoomOptions, continuation)
    }

    /**
     * Join a room with given room alias and user screen name
     */
    suspend fun joinRoomByAlias(roomAlias: String, userScreenName: String,
                                userMediaStream: UserMediaStream): JoinedRoomStatus = suspendCancellableCoroutine { continuation ->
        val roomOptions = getRoomOptions(roomAlias)
        val publishOptions = getPublishOptions(userMediaStream)
        val publishToRoomOptions = getPublishToRoomOptions(userScreenName, roomOptions, publishOptions)
        joinRoom(publishToRoomOptions, continuation)
    }

}
