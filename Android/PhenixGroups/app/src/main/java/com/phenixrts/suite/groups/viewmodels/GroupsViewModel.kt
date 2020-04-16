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
import com.phenixrts.suite.groups.common.extensions.launchIO
import com.phenixrts.suite.groups.common.extensions.launchMain
import com.phenixrts.suite.groups.models.RoomMessage
import com.phenixrts.suite.groups.models.JoinedRoomStatus
import com.phenixrts.suite.groups.models.RoomMember
import com.phenixrts.suite.groups.models.RoomStatus
import com.phenixrts.suite.groups.repository.JoinedRoomRepository
import com.phenixrts.suite.groups.repository.RoomExpressRepository
import com.phenixrts.suite.groups.repository.RoomMemberRepository
import com.phenixrts.suite.groups.repository.UserMediaRepository
import kotlinx.coroutines.flow.collect
import timber.log.Timber
import java.util.*
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class GroupsViewModel(
    private val cacheProvider: CacheProvider,
    private val preferenceProvider: PreferenceProvider,
    private val roomExpressRepository: RoomExpressRepository,
    private val userMediaRepository: UserMediaRepository
) : ViewModel() {

    private val mainRendererSurface = AndroidVideoRenderSurface()
    private var roomMemberRepository: RoomMemberRepository? = null
    private var joinedRoomRepository: JoinedRoomRepository? = null
    private var userMediaRenderer: Renderer? = null
    private var userAudioTrack: MediaStreamTrack? = null

    val memberCount = MutableLiveData<Int>().apply { value = 0 }
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

    private fun expireOldRooms() = launchIO {
        cacheProvider.cacheDao().expireOldRooms(Calendar.getInstance().expirationDate())
    }

    private fun getRoomListItems() = launchMain {
        cacheProvider.cacheDao().getVisitedRooms().collect {
            roomList.value = it
        }
    }

    private fun handleJoinedRoom(joinedRoomStatus: JoinedRoomStatus) {
        if (joinedRoomStatus.status == RequestStatus.OK) {
            joinedRoomStatus.roomService?.let { roomService ->
                joinedRoomStatus.publisher?.let { publisher ->
                    launchMain {
                        Timber.d("Joined room repository created")
                        val selfMember = RoomMember(roomService.self, true)
                        selfMember.setSelfRenderer(userMediaRenderer, mainRendererSurface, userAudioTrack)
                        currentRoomAlias.value = roomService.observableActiveRoom.value.observableAlias.value
                        joinedRoomRepository = JoinedRoomRepository(roomService, publisher)
                        roomMemberRepository = RoomMemberRepository(roomExpressRepository.roomExpress, roomService, selfMember)
                        // Update audio / video state
                        joinedRoomRepository?.switchAudioStreamState(isMicrophoneEnabled.isTrue())
                        joinedRoomRepository?.switchVideoStreamState(isVideoEnabled.isTrue())
                    }
                }
            }
        }
    }

    fun initObservers(lifecycleOwner: LifecycleOwner) = launchMain {
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

    suspend fun waitForPCast(): Unit = suspendCoroutine {
        launchMain {
            roomExpressRepository.waitForPCast()
            it.resume(Unit)
        }
    }

    suspend fun joinRoomById(owner: LifecycleOwner, roomId: String, userScreenName: String): JoinedRoomStatus = suspendCoroutine { continuation ->
        userMediaRepository.userMediaStream.observe(owner, Observer {
            launchMain {
                Timber.d("Joining room by id: $roomId")
                val joinedRoomStatus = roomExpressRepository.joinRoomById(roomId, userScreenName, it)
                userMediaRepository.userMediaStream.removeObservers(owner)
                handleJoinedRoom(joinedRoomStatus)
                continuation.resume(joinedRoomStatus)
            }
        })
    }

    suspend fun joinRoomByAlias(owner: LifecycleOwner, roomAlias: String, userScreenName: String): JoinedRoomStatus = suspendCoroutine { continuation ->
        userMediaRepository.userMediaStream.observe(owner, Observer {
            launchMain {
                Timber.d("Joining room by alias: $roomAlias")
                val joinedRoomStatus = roomExpressRepository.joinRoomByAlias(roomAlias, userScreenName, it)
                userMediaRepository.userMediaStream.removeObservers(owner)
                handleJoinedRoom(joinedRoomStatus)
                continuation.resume(joinedRoomStatus)
            }
        })
    }

    suspend fun createRoom(): RoomStatus = suspendCoroutine { continuation ->
        launchMain {
            continuation.resume(roomExpressRepository.createRoom())
        }
    }

    suspend fun sendChatMessage(message: String): RoomStatus = suspendCoroutine { continuation ->
        launchMain {
            joinedRoomRepository?.sendChatMessage(message, continuation)
                ?: continuation.resume(RoomStatus(RequestStatus.NOT_INITIALIZED, "Chat Service is not initialized"))
        }
    }

    suspend fun startUserMediaPreview(holder: SurfaceHolder): RoomStatus = suspendCoroutine { continuation ->
        mainRendererSurface.setSurfaceHolder(holder)
        if (isVideoEnabled.isTrue()) {
            launchMain {
                Timber.d("Start user media: ${isVideoEnabled.isTrue()}")
                var status = RequestStatus.OK
                if (userMediaRenderer == null) {
                    userMediaRepository.getUserMediaStream().let { userMedia ->
                        status = userMedia.status
                        if (status == RequestStatus.OK) {
                            userMediaRenderer = userMedia.userMediaStream?.mediaStream?.createRenderer()
                            userAudioTrack = userMedia.userMediaStream?.mediaStream?.audioTracks?.getOrNull(0)
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
            continuation.resume(userMediaRepository.switchCameraFacing())
        }
    }

    fun pinActiveMember(roomMember: RoomMember) = launchMain {
        roomMemberRepository?.pinActiveMember(roomMember)
    }

    fun leaveRoom() = launchMain {
        Timber.d("Leaving room")
        isInRoom.value = false
        joinedRoomRepository?.leaveRoom(cacheProvider)
        joinedRoomRepository = null
        roomMemberRepository?.dispose()
        roomMemberRepository = null
    }

    fun getChatMessages(): MutableLiveData<List<RoomMessage>> =
        joinedRoomRepository?.getObservableChatMessages() ?: MutableLiveData()

    fun getRoomMembers(): MutableLiveData<List<RoomMember>> =
        roomMemberRepository?.getObservableRoomMembers() ?: MutableLiveData()

}
