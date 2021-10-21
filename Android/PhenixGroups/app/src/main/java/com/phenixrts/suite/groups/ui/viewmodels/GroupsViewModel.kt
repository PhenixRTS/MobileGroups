/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.viewmodels

import android.view.SurfaceHolder
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.Observer
import androidx.lifecycle.ViewModel
import com.phenixrts.common.RequestStatus
import com.phenixrts.pcast.*
import com.phenixrts.pcast.android.AndroidVideoRenderSurface
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.cache.PreferenceProvider
import com.phenixrts.suite.groups.cache.entities.RoomInfoItem
import com.phenixrts.suite.groups.common.extensions.expirationDate
import com.phenixrts.suite.groups.common.extensions.isFalse
import com.phenixrts.suite.groups.common.extensions.isTrue
import com.phenixrts.suite.groups.common.getRendererOptions
import com.phenixrts.suite.groups.models.RoomMember
import com.phenixrts.suite.groups.models.RoomMessage
import com.phenixrts.suite.groups.models.RoomStatus
import com.phenixrts.suite.groups.repository.JoinedRoomRepository
import com.phenixrts.suite.groups.repository.RepositoryProvider
import com.phenixrts.suite.groups.repository.RoomMemberRepository
import com.phenixrts.suite.phenixcommon.common.launchIO
import com.phenixrts.suite.phenixcommon.common.launchMain
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.suspendCancellableCoroutine
import timber.log.Timber
import java.util.*
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class GroupsViewModel(
    private val cacheProvider: CacheProvider,
    private val preferenceProvider: PreferenceProvider,
    private val repositoryProvider: RepositoryProvider
) : ViewModel() {

    private val mainRendererSurface by lazy { AndroidVideoRenderSurface() }
    private var roomMemberRepository: RoomMemberRepository? = null
    private var joinedRoomRepository: JoinedRoomRepository? = null
    private var userMediaRenderer: Renderer? = null
    private var userAudioTrack: MediaStreamTrack? = null
    private var userVideoTrack: MediaStreamTrack? = null

    private val roomJoinedObserver = Observer<RequestStatus> { status ->
        launchMain {
            if (isInRoom.isFalse()) {
                Timber.d("Room has been joined with status: $status")
                onRoomJoined.value = status
            }
            if (status == RequestStatus.OK) {
                handleJoinedRoom()
            }
        }
    }

    private val roomMemberObserver = Observer<List<RoomMember>> { members ->
        launchMain {
            isDataLost.value = members.find { it.isActiveRenderer }?.isDataLost ?: false
            roomMembers.value = members
        }
    }

    private val chatMessageObserver = Observer<List<RoomMessage>> { messages ->
        launchMain {
            chatMessages.value = messages
        }
    }

    val memberCount = MutableLiveData<Int>().apply { value = 0 }
    val unreadMessageCount = MutableLiveData<Int>().apply { value = 0 }
    val displayName = MutableLiveData<String>()
    val isDataLost = MutableLiveData<Boolean>().apply { value = false }
    val isVideoEnabled = MutableLiveData<Boolean>().apply { value = true }
    val isMicrophoneEnabled = MutableLiveData<Boolean>().apply { value = true }
    val isInRoom = MutableLiveData<Boolean>().apply { value = false }
    val isControlsEnabled = MutableLiveData<Boolean>()
    val onPermissionRequested = MutableLiveData<Unit>()
    val roomList = MutableLiveData<List<RoomInfoItem>>()
    val onRoomJoined = MutableLiveData<RequestStatus>()
    val roomExpress = repositoryProvider.roomExpress
    val roomMembers = MutableLiveData<List<RoomMember>>()
    val chatMessages = MutableLiveData<List<RoomMessage>>()
    var currentRoomAlias: String = ""

    init {
        Timber.d("View model created")
        getRoomRepository()?.onRoomJoined?.observeForever(roomJoinedObserver)
        expireOldRooms()
        getRoomListItems()
    }

    private fun getRoomRepository() = repositoryProvider.getRoomExpressRepository()

    private fun getMediaRepository() = repositoryProvider.getUserMediaRepository()

    private fun getUserMediaStream() = repositoryProvider.getUserMediaStream()

    private fun expireOldRooms() = launchIO {
        cacheProvider.cacheDao().expireOldRooms(Calendar.getInstance().expirationDate())
    }

    private fun getRoomListItems() = launchMain {
        cacheProvider.cacheDao().getVisitedRooms(repositoryProvider.getCurrentConfiguration().backend).collect { rooms ->
            roomList.value = rooms
        }
    }

    private fun handleJoinedRoom()  = launchMain{
        roomMemberRepository?.roomMembers?.removeObserver(roomMemberObserver)
        joinedRoomRepository?.chatMessages?.removeObserver(chatMessageObserver)
        joinedRoomRepository?.clearDisposables()
        roomMemberRepository?.dispose()
        joinedRoomRepository = null
        roomMemberRepository = null
        launchIO {
            getRoomRepository()?.roomService?.let { roomService ->
                getRoomRepository()?.expressPublisher?.let { publisher ->
                    getRoomRepository()?.chatService?.let { chatService ->
                        val selfMember = RoomMember(roomService.self, true)
                        selfMember.setSelfRenderer(userMediaRenderer, mainRendererSurface, userAudioTrack, userVideoTrack)
                        val roomAlias = roomService.observableActiveRoom?.value?.observableAlias?.value ?: ""
                        currentRoomAlias = roomAlias
                        val dateRoomLeft = getRoomDateLeft(roomAlias)
                        Timber.d("Joined room repository created: $roomAlias $dateRoomLeft")
                        joinedRoomRepository = JoinedRoomRepository(roomService, chatService, publisher, dateRoomLeft)
                        roomMemberRepository = RoomMemberRepository(roomService, selfMember, repositoryProvider.getCurrentConfiguration())
                        // Update audio / video state
                        joinedRoomRepository?.switchAudioStreamState(isMicrophoneEnabled.isTrue())
                        joinedRoomRepository?.switchVideoStreamState(isVideoEnabled.isTrue())
                        launchMain {
                            // Observe chat messages and members
                            joinedRoomRepository?.chatMessages?.observeForever(chatMessageObserver)
                            roomMemberRepository?.roomMembers?.observeForever(roomMemberObserver)
                        }
                    }
                }
            }
        }
    }

    private fun getRoomDateLeft(roomAlias: String): Date {
        var dateRoomLeft = Date()
        cacheProvider.cacheDao().getVisitedRoom(roomAlias).getOrNull(0)?.let { room ->
            dateRoomLeft = room.dateLeft
        }
        Timber.d("Room with alias: $roomAlias left at: $dateRoomLeft")
        return dateRoomLeft
    }

    fun initObservers(lifecycleOwner: LifecycleOwner) = launchMain {
        displayName.value = preferenceProvider.getDisplayName()
        isMicrophoneEnabled.observe(lifecycleOwner) { enabled ->
            getMediaRepository()?.switchAudioStreamState(enabled)
            joinedRoomRepository?.switchAudioStreamState(enabled)
            roomMemberRepository?.switchAudioStreamState(enabled)
        }
        isVideoEnabled.observe(lifecycleOwner) { enabled ->
            getMediaRepository()?.switchVideoStreamState(enabled)
            joinedRoomRepository?.switchVideoStreamState(enabled)
            roomMemberRepository?.switchVideoStreamState(enabled)
        }
    }

    fun joinRoomById(roomId: String, userScreenName: String) {
        Timber.d("Joining room by id: $roomId")
        getUserMediaStream()?.let { userMediaStream ->
            getRoomRepository()?.joinRoomById(roomId, userScreenName, userMediaStream)
        }
    }

    fun joinRoomByAlias(roomAlias: String, userScreenName: String) {
        Timber.d("Joining room by alias: $roomAlias")
        getUserMediaStream()?.let { userMediaStream ->
            getRoomRepository()?.joinRoomByAlias(roomAlias, userScreenName, userMediaStream)
        }
    }

    suspend fun createRoom(): RoomStatus = suspendCoroutine { continuation ->
        launchMain {
            continuation.resume(getRoomRepository()?.createRoom() ?: RoomStatus(RequestStatus.FAILED))
        }
    }

    suspend fun sendChatMessage(message: String): RoomStatus = suspendCoroutine { continuation ->
        launchMain {
            joinedRoomRepository?.sendChatMessage(message, continuation)
                ?: continuation.resume(RoomStatus(RequestStatus.NOT_INITIALIZED, "Chat Service is not initialized"))
        }
    }

    suspend fun startUserMediaPreview(holder: SurfaceHolder): RoomStatus = suspendCancellableCoroutine { continuation ->
        mainRendererSurface.setSurfaceHolder(holder)
        var status = RequestStatus.OK
        if (isVideoEnabled.isTrue()) {
            Timber.d("Start user media: ${isVideoEnabled.isTrue()}")
            status = RequestStatus.FAILED
            getUserMediaStream()?.let { userMediaStream ->
                status = RequestStatus.OK
                if (userMediaRenderer == null) {
                    userMediaRenderer = userMediaStream.mediaStream?.createRenderer(getRendererOptions())
                    userAudioTrack = userMediaStream.mediaStream?.audioTracks?.getOrNull(0)
                    userVideoTrack = userMediaStream.mediaStream?.videoTracks?.getOrNull(0)
                    val renderStatus = userMediaRenderer?.start(mainRendererSurface)
                    if (renderStatus != RendererStartStatus.OK) {
                        status = RequestStatus.FAILED
                    }
                    Timber.d("Video render created and started: $renderStatus")
                }
            }
        }
        if (continuation.isActive) {
            continuation.resume(RoomStatus(status))
        }
    }

    suspend fun switchCameraFacing(): RequestStatus = suspendCoroutine { continuation ->
        launchMain {
            continuation.resume(getMediaRepository()?.switchCameraFacing() ?: RequestStatus.FAILED)
        }
    }

    fun pinActiveMember(roomMember: RoomMember) = launchMain {
        roomMemberRepository?.pinActiveMember(roomMember)
    }

    fun leaveRoom() = launchMain {
        Timber.d("Leaving room")
        isInRoom.value = false
        getRoomRepository()?.leaveRoom()
        roomMemberRepository?.dispose()
        roomMemberRepository = null
        joinedRoomRepository?.leaveRoom(cacheProvider)
        joinedRoomRepository = null
    }

    fun setViewingChat(isViewingChat: Boolean) {
        joinedRoomRepository?.setViewingChat(isViewingChat)
    }

    fun onConnectionLost() {
        leaveRoom()
        Timber.d("User media renderer disposed")
    }

}
