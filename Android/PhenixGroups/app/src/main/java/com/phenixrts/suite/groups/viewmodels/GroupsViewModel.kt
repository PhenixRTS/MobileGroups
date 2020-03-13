/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.viewmodels

import android.view.SurfaceHolder
import androidx.lifecycle.*
import androidx.lifecycle.Observer
import com.phenixrts.chat.ChatMessage
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.SubscribeToMemberStreamOptions
import com.phenixrts.pcast.Renderer
import com.phenixrts.pcast.RendererStartStatus
import com.phenixrts.pcast.android.AndroidVideoRenderSurface
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.cache.PreferenceProvider
import com.phenixrts.suite.groups.cache.entities.RoomInfoItem
import com.phenixrts.suite.groups.common.extensions.expirationDate
import com.phenixrts.suite.groups.models.JoinedRoomStatus
import com.phenixrts.suite.groups.models.RoomMember
import com.phenixrts.suite.groups.models.RoomStatus
import com.phenixrts.suite.groups.repository.JoinedRoomRepository
import com.phenixrts.suite.groups.repository.RoomExpressRepository
import com.phenixrts.suite.groups.repository.RoomMemberRepository
import com.phenixrts.suite.groups.repository.UserMediaRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import timber.log.Timber
import java.util.*
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class GroupsViewModel(
    private val cacheProvider: CacheProvider,
    private val preferenceProvider: PreferenceProvider,
    private val roomExpressRepository: RoomExpressRepository,
    private val userMediaRepository: UserMediaRepository,
    lifecycleOwner: LifecycleOwner
) : ViewModel() {

    private var roomMemberRepository: RoomMemberRepository? = null
    private var joinedRoomRepository: JoinedRoomRepository? = null
    var userMediaRenderer: Renderer? = null

    val displayName = MutableLiveData<String>()
    val isVideoEnabled = MutableLiveData<Boolean>()
    val isMicrophoneEnabled = MutableLiveData<Boolean>()
    val isInRoom = MutableLiveData<Boolean>()
    val isControlsEnabled = MutableLiveData<Boolean>()
    val roomList = MutableLiveData<List<RoomInfoItem>>()
    val currentRoomAlias = MutableLiveData<String>()
    val currentSessionsId = MutableLiveData<String>()

    init {
        Timber.d("View model created")
        displayName.value = preferenceProvider.getDisplayName()
        displayName.observe(lifecycleOwner, Observer {
            preferenceProvider.saveDisplayName(it)
        })
        isMicrophoneEnabled.observe(lifecycleOwner, Observer { enabled ->
            userMediaRepository.switchAudioStreams(enabled)
            joinedRoomRepository?.switchAudioStreams(enabled)
        })
        isVideoEnabled.observe(lifecycleOwner, Observer { enabled ->
            userMediaRepository.switchVideoStreams(enabled)
            joinedRoomRepository?.switchVideoStreams(enabled)
        })
        expireOldRooms()
        getRoomListItems()
    }

    private fun expireOldRooms() = viewModelScope.launch(Dispatchers.IO) {
        cacheProvider.cacheDao().expireOldRooms(Calendar.getInstance().expirationDate())
    }

    private fun getRoomListItems() = viewModelScope.launch{
        cacheProvider.cacheDao().getVisitedRooms().collect {
            roomList.value = it
        }
    }

    private fun handleJoinedRoom(joinedRoomStatus: JoinedRoomStatus) {
        if (joinedRoomStatus.status == RequestStatus.OK) {
            joinedRoomStatus.roomService?.let { roomService ->
                joinedRoomStatus.publisher?.let { publisher ->
                    viewModelScope.launch {
                        Timber.d("Joined room repository created")
                        currentRoomAlias.value = roomService.observableActiveRoom.value.observableAlias.value
                        currentSessionsId.value = roomService.self.sessionId
                        joinedRoomRepository = JoinedRoomRepository(roomService, publisher)
                        roomMemberRepository = RoomMemberRepository(roomExpressRepository.roomExpress, roomService)
                    }
                }
            }
        }
    }

    suspend fun disposeMediaRenderer(): Unit = suspendCancellableCoroutine { continuation ->
        Timber.d("Disposing media renderer")
        try {
            userMediaRenderer?.stop()
            userMediaRenderer?.dispose()
            userMediaRenderer = null
        } catch (e: Exception) {
            e.printStackTrace()
            Timber.d("Failed to dispose Renderer")
        } finally {
            Timber.d("Media renderer disposed")
            if (continuation.isActive) {
                continuation.resume(Unit)
            }
        }
    }

    suspend fun waitForPCast(): Unit = suspendCoroutine {
        viewModelScope.launch {
            roomExpressRepository.waitForPCast()
            it.resume(Unit)
        }
    }

    suspend fun joinRoomById(roomId: String, userScreenName: String): JoinedRoomStatus = suspendCoroutine { continuation ->
        viewModelScope.launch {
            userMediaRepository.getUserMediaStream().userMediaStream?.let {
                    Timber.d("Joining room by id: $roomId")
                    val joinedRoomStatus = roomExpressRepository.joinRoomById(roomId, userScreenName, it)
                    handleJoinedRoom(joinedRoomStatus)
                    continuation.resume(joinedRoomStatus)
            } ?: continuation.resume(JoinedRoomStatus(RequestStatus.FAILED))
        }
    }

    suspend fun joinRoomByAlias(roomAlias: String, userScreenName: String): JoinedRoomStatus = suspendCoroutine { continuation ->
        viewModelScope.launch {
            userMediaRepository.getUserMediaStream().userMediaStream?.let {
                    Timber.d("Joining room by alias: $roomAlias")
                    val joinedRoomStatus = roomExpressRepository.joinRoomByAlias(roomAlias, userScreenName, it)
                    handleJoinedRoom(joinedRoomStatus)
                    continuation.resume(joinedRoomStatus)
            } ?: continuation.resume(JoinedRoomStatus(RequestStatus.FAILED))
        }
    }

    suspend fun createRoom(): RoomStatus = suspendCoroutine { continuation ->
        viewModelScope.launch {
            continuation.resume(roomExpressRepository.createRoom())
        }
    }

    suspend fun sendChatMessage(message: String): RoomStatus = suspendCoroutine { continuation ->
        viewModelScope.launch {
            joinedRoomRepository?.sendChatMessage(message, continuation)
                ?: continuation.resume(RoomStatus(RequestStatus.NOT_INITIALIZED, "Chat Service is not initialized"))
        }
    }

    suspend fun startUserMediaPreview(holder: SurfaceHolder): RoomStatus = suspendCoroutine { continuation ->
        if(isVideoEnabled.value == true) {
            viewModelScope.launch {
                var status = RequestStatus.OK
                if (userMediaRenderer == null) {
                    userMediaRepository.getUserMediaStream().let { userMedia ->
                        status = userMedia.status
                        if (status == RequestStatus.OK) {
                            userMediaRenderer = userMedia.userMediaStream?.mediaStream?.createRenderer()
                            val renderStatus = userMediaRenderer?.start(AndroidVideoRenderSurface(holder))
                            if (renderStatus != RendererStartStatus.OK) {
                                status = RequestStatus.FAILED
                            }
                            Timber.d("Video render created and started: $renderStatus")
                        }
                    }
                    continuation.resume(RoomStatus(status))
                } else {
                    launch {
                        val renderStatus = restartMediaRenderer(userMediaRenderer, holder)
                        if (renderStatus != RendererStartStatus.OK) {
                            status = RequestStatus.FAILED
                        }
                        Timber.d("Video render re-started: $renderStatus")
                        continuation.resume(RoomStatus(status))
                    }
                }
            }
        }
    }

    suspend fun subscribeToMemberStream(roomMember: RoomMember, options: SubscribeToMemberStreamOptions): RoomStatus
            = suspendCoroutine { continuation ->
        viewModelScope.launch {
            continuation.resume(roomMemberRepository?.subscribeToMemberMedia(roomMember, options)
                ?: RoomStatus(RequestStatus.NOT_INITIALIZED, "Subscriber Repository is not initialized")
            )
        }
    }

    fun leaveRoom() = viewModelScope.launch {
        Timber.d("Leaving room")
        joinedRoomRepository?.leaveRoom(cacheProvider)
        joinedRoomRepository = null
        roomMemberRepository?.dispose()
        roomMemberRepository = null
    }

    fun getChatMessages(): MutableLiveData<List<ChatMessage>> =
        joinedRoomRepository?.getObservableChatMessages() ?: MutableLiveData()

    fun getRoomMembers(): MutableLiveData<List<RoomMember>>
            = roomMemberRepository?.getObservableRoomMembers() ?: MutableLiveData()

    fun stopUserMediaPreview() = viewModelScope.launch {
        Timber.d("Stopping media renderer")
        userMediaRenderer?.stop()
    }

    suspend fun restartMediaRenderer(renderer: Renderer?, surfaceHolder: SurfaceHolder): RendererStartStatus
            = suspendCoroutine { continuation ->
        viewModelScope.launch {
            try {
                renderer?.stop()
                // TODO: Remove delay once SDK is updated to not throw conflict error when called quickly
                delay(RENDERER_RESTART_DELAY)
                Timber.d("Restarting media renderer: $renderer $surfaceHolder")
                renderer?.start(AndroidVideoRenderSurface(surfaceHolder))?.let { rendererStatus ->
                    continuation.resume(rendererStatus)
                } ?: continuation.resume(RendererStartStatus.FAILED)
            } catch (e: Exception) {
                Timber.d("Failed to restart renderer")
                continuation.resume(RendererStartStatus.FAILED)
            }
        }
    }

    companion object {
        const val RENDERER_RESTART_DELAY = 400L
    }
}
