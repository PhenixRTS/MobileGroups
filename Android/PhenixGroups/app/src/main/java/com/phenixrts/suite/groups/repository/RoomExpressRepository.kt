/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import android.view.SurfaceHolder
import androidx.lifecycle.MutableLiveData
import com.phenixrts.chat.ChatMessage
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.JoinRoomOptions
import com.phenixrts.express.RoomExpress
import com.phenixrts.express.RoomExpressFactory
import com.phenixrts.pcast.*
import com.phenixrts.pcast.android.AndroidVideoRenderSurface
import com.phenixrts.room.RoomServiceFactory
import com.phenixrts.room.RoomType
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.common.getRoomCode
import com.phenixrts.suite.groups.cache.entities.RoomInfoItem
import com.phenixrts.suite.groups.common.extensions.getUserMedia
import com.phenixrts.suite.groups.models.RoomStatus
import com.phenixrts.suite.groups.models.UserMediaStatus
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.flow
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

    private val userMediaOptions = UserMediaOptions().apply {
        videoOptions.capabilityConstraints[DeviceCapability.FACING_MODE] = listOf(DeviceConstraint(FacingMode.USER))
        videoOptions.capabilityConstraints[DeviceCapability.HEIGHT] = listOf(DeviceConstraint(480.0))
        videoOptions.capabilityConstraints[DeviceCapability.FRAME_RATE] = listOf(DeviceConstraint(15.0))
        audioOptions.capabilityConstraints[DeviceCapability.AUDIO_ECHO_CANCELATION_MODE] =
            listOf(DeviceConstraint(AudioEchoCancelationMode.ON))
    }

    private var joinedRoomRepository: JoinedRoomRepository? = null
    private var userMediaRenderer: Renderer? = null
    private var userMediaStream: UserMediaStream? = null

    private fun getUserMediaStream(): Flow<UserMediaStatus> = flow {
        emit(userMediaStream?.let { UserMediaStatus(userMediaStream = it) }
            ?: roomExpress.pCastExpress.getUserMedia(userMediaOptions))
    }

    /**
     * Try to join a room with given room options and block until executed
     */
    private fun joinRoom(joinRoomOptions: JoinRoomOptions, continuation: Continuation<RequestStatus>) {
        roomExpress.joinRoom(joinRoomOptions) { status, roomService ->
            Timber.d("Room join completed with status: $status")
            if (status == RequestStatus.OK) {
                joinedRoomRepository = JoinedRoomRepository(roomService)
                val room = roomService.observableActiveRoom.value
                cacheProvider.cacheDao().insertRoom(RoomInfoItem(room.roomId, room.observableAlias.value))
            }
            continuation.resume(status)
        }
    }

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
     * Start observing chat messages for current room
     */
    fun getObservableChatMessages(): MutableLiveData<List<ChatMessage>> {
        return joinedRoomRepository?.getObservableChatMessages() ?: MutableLiveData(mutableListOf())
    }

    /**
     * Used to send a chat message
     */
    suspend fun sendChatMessage(message: String): RoomStatus = suspendCoroutine { continuation ->
        joinedRoomRepository?.sendChatMessage(message, continuation)
            ?: continuation.resume(RoomStatus(RequestStatus.NOT_INITIALIZED, "Chat Service is not initialized"))
    }

    suspend fun startUserVideoPreview(holder: SurfaceHolder): RoomStatus = suspendCoroutine {
        // TODO: If the user media object is reused - then either the camera is never released - or released and not accessible
        launch {
            getUserMediaStream().collect { userMediaStatus ->
                if (userMediaStatus.status == RequestStatus.OK && userMediaRenderer == null) {
                    userMediaRenderer = userMediaStatus.userMediaStream?.mediaStream?.createRenderer()
                    userMediaRenderer?.start(AndroidVideoRenderSurface(holder))
                    Timber.d("Video renderer started")
                }
                it.resume(RoomStatus(userMediaStatus.status))
            }
        }
    }

    suspend fun stopMediaStream(): Unit = suspendCoroutine {
        userMediaRenderer?.stop()
        userMediaStream?.mediaStream?.stop()
        userMediaStream = null
        userMediaRenderer = null
        it.resume(Unit)
    }

    /**
     * Used to leave current active room
     */
    suspend fun leaveRoom(): Unit = suspendCoroutine {
        joinedRoomRepository?.leaveRoom()?.let { roomId ->
            cacheProvider.cacheDao().updateRoomLeftDate(roomId, Date())
        }
        joinedRoomRepository = null
        it.resume(Unit)
    }
}
