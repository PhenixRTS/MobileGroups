/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.viewmodels

import android.view.SurfaceHolder
import androidx.lifecycle.*
import androidx.lifecycle.Observer
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.SubscribeToMemberStreamOptions
import com.phenixrts.pcast.MediaStreamTrack
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
import com.phenixrts.suite.groups.repository.*
import com.phenixrts.suite.phenixcommon.common.launchIO
import com.phenixrts.suite.phenixcommon.common.launchMain
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.runBlocking
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

    val memberCount = MutableLiveData<Int>().apply { value = 0 }
    val unreadMessageCount = MutableLiveData<Int>().apply { value = 0 }
    val displayName = MutableLiveData<String>()
    val isVideoEnabled = MutableLiveData<Boolean>().apply { value = true }
    val isMicrophoneEnabled = MutableLiveData<Boolean>().apply { value = true }
    val isInRoom = MutableLiveData<Boolean>().apply { value = false }
    val isControlsEnabled = MutableLiveData<Boolean>()
    val onPermissionRequested = MutableLiveData<Unit>()
    val roomList = MutableLiveData<List<RoomInfoItem>>()
    val currentRoomAlias = MutableLiveData<String>()

    init {
        Timber.d("View model created")
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

    private fun handleJoinedRoom(joinedRoomStatus: JoinedRoomStatus) {
        if (joinedRoomStatus.status == RequestStatus.OK) {
            joinedRoomStatus.roomService?.let { roomService ->
                joinedRoomStatus.publisher?.let { publisher ->
                    runBlocking {
                        val selfMember = RoomMember(roomService.self, true)
                        selfMember.setSelfRenderer(userMediaRenderer, mainRendererSurface, userAudioTrack)
                        val roomAlias = roomService.observableActiveRoom.value.observableAlias.value
                        currentRoomAlias.value = roomAlias
                        val dateRoomLeft = getRoomDateLeft(roomAlias)
                        Timber.d("Joined room repository created: $roomAlias $dateRoomLeft")
                        joinedRoomRepository = JoinedRoomRepository(roomService, publisher, dateRoomLeft)
                        roomMemberRepository = RoomMemberRepository(repositoryProvider.roomExpress!!, roomService, selfMember)
                        // Update audio / video state
                        joinedRoomRepository?.switchAudioStreamState(isMicrophoneEnabled.isTrue())
                        joinedRoomRepository?.switchVideoStreamState(isVideoEnabled.isTrue())
                    }
                }
            }
        }
    }

    private suspend fun getRoomDateLeft(roomAlias: String) = suspendCoroutine<Date> { continuation ->
        launchIO {
            var dateRoomLeft = Date()
            cacheProvider.cacheDao().getVisitedRoom(roomAlias).getOrNull(0)?.let { room ->
                dateRoomLeft = room.dateLeft
            }
            Timber.d("Room with alias: $roomAlias left at: $dateRoomLeft")
            continuation.resume(dateRoomLeft)
        }
    }

    fun initObservers(lifecycleOwner: LifecycleOwner) = launchMain {
        displayName.value = preferenceProvider.getDisplayName()
        isMicrophoneEnabled.observe(lifecycleOwner, Observer { enabled ->
            getMediaRepository()?.switchAudioStreamState(enabled)
            joinedRoomRepository?.switchAudioStreamState(enabled)
            roomMemberRepository?.switchAudioStreamState(enabled)
        })
        isVideoEnabled.observe(lifecycleOwner, Observer { enabled ->
            getMediaRepository()?.switchVideoStreamState(enabled)
            joinedRoomRepository?.switchVideoStreamState(enabled)
            roomMemberRepository?.switchVideoStreamState(enabled)
        })
    }

    suspend fun joinRoomById(roomId: String, userScreenName: String): JoinedRoomStatus
            = suspendCancellableCoroutine { continuation ->
        Timber.d("Joining room by id: $roomId")
        getUserMediaStream()?.let { userMediaStream ->
            launchMain {
                val joinedRoomStatus = getRoomRepository()?.joinRoomById(roomId, userScreenName, userMediaStream)
                    ?: JoinedRoomStatus(RequestStatus.FAILED)
                handleJoinedRoom(joinedRoomStatus)
                if (continuation.isActive) {
                    continuation.resume(joinedRoomStatus)
                }
            }
        }
    }

    suspend fun joinRoomByAlias(roomAlias: String, userScreenName: String): JoinedRoomStatus
            = suspendCancellableCoroutine { continuation ->
        Timber.d("Joining room by alias: $roomAlias")
        getUserMediaStream()?.let { userMediaStream ->
            launchMain {
                Timber.d("Joining room by alias: $roomAlias")
                val joinedRoomStatus = getRoomRepository()?.joinRoomByAlias(roomAlias, userScreenName, userMediaStream)
                    ?: JoinedRoomStatus(RequestStatus.FAILED)
                handleJoinedRoom(joinedRoomStatus)
                if (continuation.isActive) {
                    continuation.resume(joinedRoomStatus)
                }
            }
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
                    userMediaRenderer = userMediaStream.mediaStream?.createRenderer()
                    userAudioTrack = userMediaStream.mediaStream?.audioTracks?.getOrNull(0)
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

    suspend fun subscribeToMemberStream(roomMember: RoomMember, options: SubscribeToMemberStreamOptions): RoomStatus
            = suspendCoroutine { continuation ->
        launchMain {
            if (roomMember.isSelf) {
                continuation.resume(RoomStatus(RequestStatus.OK))
            } else {
                continuation.resume(
                    roomMemberRepository?.subscribeToMemberMedia(roomMember, options)
                        ?: RoomStatus(RequestStatus.NOT_INITIALIZED, "Subscriber Repository is not initialized")
                )
            }
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
        roomMemberRepository?.dispose()
        roomMemberRepository = null
        joinedRoomRepository?.leaveRoom(cacheProvider)
        joinedRoomRepository = null
    }

    fun getChatMessages(): MutableLiveData<List<RoomMessage>> =
        joinedRoomRepository?.getObservableChatMessages() ?: MutableLiveData()

    fun setViewingChat(isViewingChat: Boolean) {
        joinedRoomRepository?.setViewingChat(isViewingChat)
    }

    fun getRoomMembers(): MutableLiveData<List<RoomMember>> =
        roomMemberRepository?.getObservableRoomMembers() ?: MutableLiveData()

}
