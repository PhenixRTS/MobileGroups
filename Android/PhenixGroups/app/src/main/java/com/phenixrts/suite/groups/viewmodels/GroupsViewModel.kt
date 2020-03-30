/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.viewmodels

import android.view.SurfaceHolder
import androidx.lifecycle.*
import androidx.lifecycle.Observer
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.SubscribeToMemberStreamOptions
import com.phenixrts.pcast.Renderer
import com.phenixrts.pcast.RendererStartStatus
import com.phenixrts.pcast.android.AndroidVideoRenderSurface
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.cache.PreferenceProvider
import com.phenixrts.suite.groups.cache.entities.RoomInfoItem
import com.phenixrts.suite.groups.common.extensions.expirationDate
import com.phenixrts.suite.groups.common.extensions.isTrue
import com.phenixrts.suite.groups.models.RoomMessage
import com.phenixrts.suite.groups.models.JoinedRoomStatus
import com.phenixrts.suite.groups.models.RoomMember
import com.phenixrts.suite.groups.models.RoomStatus
import com.phenixrts.suite.groups.repository.JoinedRoomRepository
import com.phenixrts.suite.groups.repository.RoomExpressRepository
import com.phenixrts.suite.groups.repository.RoomMemberRepository
import com.phenixrts.suite.groups.repository.UserMediaRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import timber.log.Timber
import java.util.*
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class GroupsViewModel(
    private val cacheProvider: CacheProvider,
    private val preferenceProvider: PreferenceProvider,
    private val roomExpressRepository: RoomExpressRepository,
    private val userMediaRepository: UserMediaRepository,
    private val mainSurfaceHolder: SurfaceHolder,
    lifecycleOwner: LifecycleOwner
) : ViewModel() {

    private val mainRendererSurface = AndroidVideoRenderSurface()
    private var roomMemberRepository: RoomMemberRepository? = null
    private var joinedRoomRepository: JoinedRoomRepository? = null
    private var userMediaRenderer: Renderer? = null

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
        initObservers(lifecycleOwner)
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
                        // Update audio / video state
                        joinedRoomRepository?.switchAudioStreamState(isMicrophoneEnabled.isTrue())
                        joinedRoomRepository?.switchVideoStreamState(isVideoEnabled.isTrue())
                    }
                }
            }
        }
    }

    fun initObservers(lifecycleOwner: LifecycleOwner) {
        viewModelScope.launch(Dispatchers.Main) {
            displayName.value = preferenceProvider.getDisplayName()
            isMicrophoneEnabled.observe(lifecycleOwner, Observer { enabled ->
                userMediaRepository.switchAudioStreamState(enabled)
                joinedRoomRepository?.switchAudioStreamState(enabled)
                roomMemberRepository?.switchAudioStreamState(enabled)
            })
            isVideoEnabled.observe(lifecycleOwner, Observer { enabled ->
                userMediaRepository.switchVideoStreamState(enabled)
                joinedRoomRepository?.switchVideoStreamState(enabled)
                roomMemberRepository?.switchVideoStreamState(enabled)
            })
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

    suspend fun startUserMediaPreview(holder: SurfaceHolder?): RoomStatus = suspendCoroutine { continuation ->
        if (isVideoEnabled.isTrue()) {
            viewModelScope.launch {
                Timber.d("Start user media: ${isVideoEnabled.isTrue()} holder: $holder")
                var status = RequestStatus.OK
                mainRendererSurface.setSurfaceHolder(holder ?: mainSurfaceHolder)
                if (userMediaRenderer == null) {
                    userMediaRepository.getUserMediaStream().let { userMedia ->
                        status = userMedia.status
                        if (status == RequestStatus.OK) {
                            userMediaRenderer = userMedia.userMediaStream?.mediaStream?.createRenderer()
                            val renderStatus = userMediaRenderer?.start(mainRendererSurface)
                            if (renderStatus != RendererStartStatus.OK) {
                                status = RequestStatus.FAILED
                            }
                            Timber.d("Video render created and started: $renderStatus")
                        }
                    }
                }
                continuation.resume(RoomStatus(status))
            }
        } else {
            continuation.resume(RoomStatus(RequestStatus.FAILED))
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

    fun pinActiveMember(roomMember: RoomMember) = viewModelScope.launch {
        roomMemberRepository?.pinActiveMember(roomMember)
    }

    fun leaveRoom() = viewModelScope.launch {
        Timber.d("Leaving room")
        joinedRoomRepository?.leaveRoom(cacheProvider)
        joinedRoomRepository = null
        roomMemberRepository?.dispose()
        roomMemberRepository = null
    }

    fun getChatMessages(): MutableLiveData<List<RoomMessage>> =
        joinedRoomRepository?.getObservableChatMessages() ?: MutableLiveData()

    fun getRoomMembers(): MutableLiveData<List<RoomMember>>
            = roomMemberRepository?.getObservableRoomMembers() ?: MutableLiveData()

}
