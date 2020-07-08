/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

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
import com.phenixrts.suite.groups.models.RoomExpressConfiguration
import com.phenixrts.suite.groups.models.RoomStatus
import com.phenixrts.suite.phenixcommon.common.launchIO
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.suspendCancellableCoroutine
import timber.log.Timber
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class RoomExpressRepository(
    private val cacheProvider: CacheProvider,
    private val roomExpress: RoomExpress,
    private val configuration: RoomExpressConfiguration
) {

    private var isDisposed = false

    /**
     * Try to join a room with given room options and block until executed
     */
    private fun joinRoom(publishToRoomOptions: PublishToRoomOptions,
                         continuation: CancellableContinuation<JoinedRoomStatus>) = launchIO {
        roomExpress.publishToRoom(publishToRoomOptions) { status: RequestStatus, roomService: RoomService?,
                                                          publisher: ExpressPublisher? ->
            Timber.d("Room join completed with status: $status")
            var requestStatus = status
            if (status == RequestStatus.OK) {
                roomService?.observableActiveRoom?.value?.let { room ->
                    cacheProvider.cacheDao().insertRoom(RoomInfoItem(room.roomId, room.observableAlias.value, configuration.backend))
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
    suspend fun joinRoomById(roomId: String, userScreenName: String, userMediaStream: UserMediaStream): JoinedRoomStatus
            = suspendCancellableCoroutine { continuation ->
        val publishOptions = getPublishOptions(userMediaStream)
        val publishToRoomOptions = getPublishToRoomOptions(roomId, userScreenName, publishOptions)
        joinRoom(publishToRoomOptions, continuation)
    }

    /**
     * Join a room with given room alias and user screen name
     */
    suspend fun joinRoomByAlias(roomAlias: String, userScreenName: String, userMediaStream: UserMediaStream): JoinedRoomStatus
            = suspendCancellableCoroutine { continuation ->
        val roomOptions = getRoomOptions(roomAlias)
        val publishOptions = getPublishOptions(userMediaStream)
        val publishToRoomOptions = getPublishToRoomOptions(userScreenName, roomOptions, publishOptions)
        joinRoom(publishToRoomOptions, continuation)
    }

    fun dispose() = try {
        isDisposed = true
        // TODO: Neither of these can be disposed without breaking UserMediaStream
        //roomExpress.pCastExpress.pCast.dispose()
        //roomExpress.pCastExpress.dispose()
        //roomExpress.dispose()
        Timber.d("Room express repository disposed")
    } catch (e: Exception) {
        Timber.d("Failed to dispose room express repository")
    }

}
