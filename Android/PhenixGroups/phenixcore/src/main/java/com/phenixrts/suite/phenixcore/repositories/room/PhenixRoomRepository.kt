/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.phenixcore.repositories.room

import android.os.Handler
import android.os.Looper
import android.view.SurfaceView
import android.widget.ImageView
import com.phenixrts.chat.RoomChatService
import com.phenixrts.chat.RoomChatServiceFactory
import com.phenixrts.common.Disposable
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.*
import com.phenixrts.media.video.android.AndroidVideoFrame
import com.phenixrts.pcast.FacingMode
import com.phenixrts.pcast.Renderer
import com.phenixrts.pcast.UserMediaStream
import com.phenixrts.pcast.android.AndroidReadVideoFrameCallback
import com.phenixrts.pcast.android.AndroidVideoRenderSurface
import com.phenixrts.room.*
import com.phenixrts.suite.phenixcore.BuildConfig
import com.phenixrts.suite.phenixcore.common.*
import com.phenixrts.suite.phenixcore.repositories.core.common.*
import com.phenixrts.suite.phenixcore.repositories.core.common.getPublishOptions
import com.phenixrts.suite.phenixcore.repositories.core.common.getPublishToRoomOptions
import com.phenixrts.suite.phenixcore.repositories.core.common.getRoomOptions
import com.phenixrts.suite.phenixcore.repositories.models.*
import com.phenixrts.suite.phenixcore.repositories.room.models.PhenixCoreMember
import kotlinx.coroutines.flow.asSharedFlow
import timber.log.Timber
import java.util.*

internal class PhenixRoomRepository(
    private val roomExpress: RoomExpress,
    private val configuration: PhenixConfiguration
) {

    private val videoRenderSurface by lazy { AndroidVideoRenderSurface() }
    private var userMediaStream: UserMediaStream? = null
    private var selfVideoRenderer: Renderer? = null
    private var selfPreviewImageView: ImageView? = null
    private var selfPreviewConfiguration: PhenixFrameReadyConfiguration? = null
    private var isFirstFrameDrawn = false

    private val frameCallback = Renderer.FrameReadyForProcessingCallback { frameNotification ->
        frameNotification?.read(object : AndroidReadVideoFrameCallback() {
            override fun onVideoFrameEvent(videoFrame: AndroidVideoFrame?) {
                videoFrame?.bitmap?.prepareBitmap(selfPreviewConfiguration)?.let { bitmap ->
                    selfPreviewImageView?.drawFrameBitmap(bitmap, isFirstFrameDrawn) {
                        isFirstFrameDrawn = true
                    }
                }
            }
        })
    }

    private val rawMembers = mutableListOf<PhenixCoreMember>()
    private val rawMessages = mutableListOf<PhenixMessage>()
    private val rawRooms = mutableListOf<PhenixRoom>()
    private val chatServices = mutableListOf<Pair<RoomChatService, String>>()
    private var roomConfiguration: PhenixRoomConfiguration? = null

    private val microphoneFailureHandler = Handler(Looper.getMainLooper())
    private val cameraFailureHandler = Handler(Looper.getMainLooper())
    private val microphoneFailureRunnable = Runnable {
        Timber.d("Audio recording has stopped")
        selfCoreMember?.isAudioEnabled = false
        _members.tryEmit(rawMembers.asPhenixMembers())
    }
    private val videoFailureRunnable = Runnable {
        Timber.d("Video recording is stopped")
        selfCoreMember?.isVideoEnabled = false
        _members.tryEmit(rawMembers.asPhenixMembers())
    }

    private val _onError = ConsumableSharedFlow<PhenixError>()
    private val _onEvent = ConsumableSharedFlow<PhenixEvent>()
    private val _members = ConsumableSharedFlow<List<PhenixMember>>(canReplay = true)
    private val _messages = ConsumableSharedFlow<List<PhenixMessage>>(canReplay = true)
    private val _rooms = ConsumableSharedFlow<List<PhenixRoom>>(canReplay = true)
    private var _memberCount = ConsumableSharedFlow<Long>(canReplay = true)

    private val disposables: MutableList<Disposable?> = mutableListOf()
    private val joinedDate = Date()
    private var currentFacingMode = FacingMode.USER

    private var selfCoreMember: PhenixCoreMember? = null
    private var publisher: ExpressPublisher? = null
    private var roomService: RoomService? = null

    val members = _members.asSharedFlow()
    val messages = _messages.asSharedFlow()
    val rooms = _rooms.asSharedFlow()
    val onError = _onError.asSharedFlow()
    val onEvent = _onEvent.asSharedFlow()
    val memberCount = _memberCount.asSharedFlow()

    init {
        roomExpress.pCastExpress.getUserMedia { userMedia ->
            userMediaStream = userMedia
            setSelfVideoEnabled(true)
        }
    }

    fun joinRoom(configuration: PhenixRoomConfiguration) {
        _onEvent.tryEmit(PhenixEvent.PHENIX_ROOM_JOINING.apply { data = roomConfiguration })
        Timber.d("Joining room with configuration: $configuration")
        roomExpress.joinRoom(configuration) { service ->
            roomService = service
            if (roomService == null) {
                _onError.tryEmit(PhenixError.JOIN_ROOM_FAILED.apply { data = roomConfiguration })
            } else {
                onRoomJoined(configuration, service, PhenixEvent.PHENIX_ROOM_JOINED)
            }
        }
    }

    fun createRoom(configuration: PhenixRoomConfiguration) {
        roomConfiguration = configuration
        _onEvent.tryEmit(PhenixEvent.PHENIX_ROOM_CREATING.apply { data = roomConfiguration })
        Timber.d("Creating room with configuration: $configuration")
        roomExpress.createRoom(configuration) { status ->
            if (status == RequestStatus.OK) {
                _onEvent.tryEmit(PhenixEvent.PHENIX_ROOM_CREATED.apply { data = roomConfiguration })
            } else {
                _onError.tryEmit(PhenixError.CREATE_ROOM_FAILED.apply { data = roomConfiguration })
            }
        }
    }

    fun publishToRoom(roomConfiguration: PhenixRoomConfiguration) {
        if (userMediaStream == null) {
            _onError.tryEmit(PhenixError.PUBLISH_ROOM_FAILED.apply { data = roomConfiguration })
            return
        }
        Timber.d("Publishing to room: $roomConfiguration")
        _onEvent.tryEmit(PhenixEvent.PHENIX_ROOM_PUBLISHING.apply { data = roomConfiguration })
        val roomOptions = getRoomOptions(roomConfiguration)
        val publishOptions = getPublishOptions(
            userMediaStream!!,
            configuration.edgeToken ?: configuration.publishToken,
            emptyList()
        )
        val publishToRoomOptions = getPublishToRoomOptions(roomOptions, publishOptions, roomConfiguration)
        roomExpress.publishInRoom(publishToRoomOptions) { publisher, service ->
            this.publisher = publisher
            this.roomService = service
            if (publisher == null || service == null) {
                _onError.tryEmit(PhenixError.PUBLISH_ROOM_FAILED.apply { data = roomConfiguration })
            } else {
                onRoomJoined(roomConfiguration, service, PhenixEvent.PHENIX_ROOM_PUBLISHED)
            }
        }
    }

    fun stopPublishing() {
        Timber.d("Stopping media publishing")
        publisher?.stop()
    }

    fun leaveRoom() {
        stopPublishing()
        roomService?.leaveRoom { _, status ->
            Timber.d("Room left with status: $status")
            dispose()
            rawRooms.clear()
            _rooms.tryEmit(rawRooms.map { it.copy() })
            _onEvent.tryEmit(PhenixEvent.PHENIX_ROOM_LEFT.apply { data = roomConfiguration })
        }
    }

    fun flipCamera() {
        val facingMode = if (currentFacingMode == FacingMode.USER) FacingMode.ENVIRONMENT else FacingMode.USER
        userMediaStream?.applyOptions(getUserMediaOptions(facingMode))?.let { status ->
            if (status == RequestStatus.OK) {
                currentFacingMode = facingMode
                _onEvent.tryEmit(PhenixEvent.CAMERA_FLIPPED)
            } else {
                _onError.tryEmit(PhenixError.CAMERA_FLIP_FAILED)
            }
        }
    }

    fun setVideoEnabled(memberId: String, enabled: Boolean) {
        Timber.d("Switching video streams: $enabled for: $memberId")
        rawMembers.find { it.memberId == memberId }?.run {
            isVideoEnabled = enabled
            if (isSelf) {
                if (enabled) {
                    publisher?.enableVideo()
                } else {
                    publisher?.disableVideo()
                }
            }
        }
    }

    fun setSelfVideoEnabled(enabled: Boolean) {
        rawMembers.find { it.isSelf }?.run {
            Timber.d("Switching self preview and publisher video state: $enabled")
            isVideoEnabled = enabled
            if (enabled) {
                publisher?.enableVideo()
            } else {
                publisher?.disableVideo()
            }
        }
        if (enabled) {
            if (selfVideoRenderer != null) return
            selfVideoRenderer = userMediaStream?.mediaStream?.createRenderer(rendererOptions)
            val status = selfVideoRenderer?.start(videoRenderSurface)
            selfVideoRenderer?.start()
            Timber.d("Self video started: $status")
        } else {
            if (selfVideoRenderer == null) return
            selfVideoRenderer?.stop()
            selfVideoRenderer = null
            Timber.d("Self video ended")
        }
    }

    fun setAudioEnabled(memberId: String, enabled: Boolean) {
        Timber.d("Switching audio streams: $enabled for: $memberId in $rawMembers")
        rawMembers.find { it.memberId == memberId }?.run {
            isAudioEnabled = enabled
            if (isSelf) {
                if (enabled) {
                    publisher?.enableAudio()
                } else {
                    publisher?.disableAudio()
                }
            }
        }
    }

    fun setSelfAudioEnabled(enabled: Boolean) {
        rawMembers.find { it.isSelf }?.run {
            Timber.d("Switching self preview and publisher audio state: $enabled")
            isAudioEnabled = enabled
            if (enabled) {
                publisher?.enableAudio()
            } else {
                publisher?.disableAudio()
            }
        }
    }

    fun setAudioLevel(memberId: String, level: Float) {
        Timber.d("Changing member audio level: $memberId, $level")
        rawMembers.find { it.memberId == memberId }?.audioLevel = if (level < 0f) 0f else if (level > 1f) 1f else level
    }

    fun updateMember(memberId: String, role: MemberRole?, state: MemberState?, name: String?) {
        rawMembers.find { it.memberId == memberId }?.let { member ->
            Timber.d("Updating member: $member with: ${role ?: member.memberRole}, ${state ?: member.memberState}, ${name ?: member.memberName}")
            member.updateMember(
                role ?: member.memberRole,
                state ?: member.memberState,
                name ?: member.memberName,
                onError = {
                    _onError.tryEmit(PhenixError.UPDATE_MEMBER_FAILED)
                }
            )
        }
    }

    fun sendMessage(message: String, mimeType: String) {
        Timber.d("Can send message: $message, ${chatServices.any { it.second.contains(mimeType) }} on: $mimeType")
        if (mimeType.isBlank() && chatServices.isNotEmpty()) {
            chatServices.forEach { service ->
                service.first.sendMessageToRoom(message) { status, _ ->
                    Timber.d("Message: $message sent with status: $status")
                    if (status == RequestStatus.OK) {
                        _onEvent.tryEmit(PhenixEvent.MESSAGE_SENT)
                    } else {
                        _onError.tryEmit(PhenixError.SEND_MESSAGE_FAILED)
                    }
                }
            }
        } else {
            chatServices.firstOrNull { it.second.contains(mimeType) }?.first?.sendMessageToRoom(message, mimeType) { status, _ ->
                Timber.d("Message: $message sent with status: $status")
                if (status == RequestStatus.OK) {
                    _onEvent.tryEmit(PhenixEvent.MESSAGE_SENT)
                } else {
                    _onError.tryEmit(PhenixError.SEND_MESSAGE_FAILED)
                }
            } ?: _onError.tryEmit(PhenixError.SEND_MESSAGE_FAILED)
        }
    }

    fun selectMember(memberId: String, isSelected: Boolean) {
        Timber.d("Selecting member: ${rawMembers.find { it.member.sessionId == memberId }}, $isSelected")
        rawMembers.find { it.member.sessionId == memberId }?.isSelected = isSelected
    }

    fun renderOnSurface(memberId: String, surfaceView: SurfaceView?) {
        Timber.d("Render on surface called")
        videoRenderSurface.setSurfaceHolder(surfaceView?.holder)
        rawMembers.find { it.memberId == memberId }?.renderOnSurface(surfaceView)
    }

    fun renderOnImage(memberId: String, imageView: ImageView?, configuration: PhenixFrameReadyConfiguration?) {
        Timber.d("Render on image called")
        rawMembers.find { it.memberId == memberId }?.renderOnImage(imageView, configuration)
    }

    fun previewOnSurface(surfaceView: SurfaceView?) {
        Timber.d("Preview on surface called")
        videoRenderSurface.setSurfaceHolder(surfaceView?.holder)
    }

    fun previewOnImage(imageView: ImageView?, configuration: PhenixFrameReadyConfiguration?) {
        Timber.d("Preview on image called")
        selfPreviewImageView = imageView
        selfPreviewConfiguration = configuration
        val tracks = userMediaStream?.mediaStream?.videoTracks
        tracks?.lastOrNull()?.let { videoTrack ->
            val callback = if (selfPreviewImageView == null) null else frameCallback
            if (callback == null) isFirstFrameDrawn = false
            selfVideoRenderer?.setFrameReadyCallback(videoTrack, null)
            selfVideoRenderer?.setFrameReadyCallback(videoTrack, callback)
        }
    }

    fun subscribeRoomMembers() {
        roomConfiguration?.joinSilently = false
        var videoRenderers = 0
        rawMembers.forEach { member ->
            val canRenderVideo = videoRenderers <= (roomConfiguration?.maxVideoRenderers ?: BuildConfig.MAX_VIDEO_RENDERERS)
            member.subscribeToMemberMedia(canRenderVideo)
            if (member.isVideoRendering) videoRenderers++
            launchIO { member.onUpdated.collect { _members.tryEmit(rawMembers.asPhenixMembers()) } }
            launchIO { member.onError.collect { _onError.tryEmit(it) } }
        }
    }

    private fun dispose() {
        rawMessages.clear()
        rawMembers.forEach { it.dispose() }
        rawMembers.clear()
        chatServices.forEach { it.first.dispose() }
        chatServices.clear()
        roomService?.dispose()
        roomService = null
        disposables.forEach { disposable ->
            disposable?.dispose()
        }
        disposables.clear()
    }

    private fun onRoomJoined(configuration: PhenixRoomConfiguration, service: RoomService?, event: PhenixEvent) {
        roomConfiguration = configuration
        selfCoreMember = PhenixCoreMember(roomService!!.self, true, roomExpress, configuration)
        rawMembers.add(selfCoreMember!!)
        chatServices.forEach { it.first.dispose() }
        chatServices.clear()
        if (configuration.messageConfigs.isNotEmpty()) {
            configuration.messageConfigs.forEach { messageConfig ->
                chatServices.add(
                    Pair(
                        RoomChatServiceFactory.createRoomChatService(
                            service,
                            messageConfig.batchSize,
                            listOf(messageConfig.mimeType).toTypedArray()
                        ),
                        messageConfig.mimeType
                    )
                )
            }
        } else {
            chatServices.add(Pair(RoomChatServiceFactory.createRoomChatService(service), ""))
        }
        if (!configuration.joinSilently) {
            updateMember(
                selfCoreMember!!.memberId,
                configuration.memberRole,
                MemberState.ACTIVE,
                configuration.memberName
            )
        }
        observeRoomStatus()
        observeChatServices()
        observeMemberCount()
        observeRoomMembers()
        observeMediaState()
        roomService?.observableActiveRoom?.value?.let { room ->
            if (rawRooms.none { it.id == room.roomId }) {
                rawRooms.add(PhenixRoom(id = room.roomId, alias = room.observableAlias.value))
            }
            _rooms.tryEmit(rawRooms.map { it.copy() })
            _onEvent.tryEmit(event.apply { data = configuration })
        }
    }

    private fun observeRoomStatus() {
        roomExpress.pCastExpress.observableIsOnlineStatus.subscribe { isOnline ->
            if (!isOnline) {
                Timber.d("Online state changed: $isOnline")
                _onError.tryEmit(PhenixError.ROOM_GONE.apply { data = roomConfiguration })
            }
        }.run { disposables.add(this) }
    }

    private fun observeMediaState() {
        userMediaStream?.run {
            mediaStream.videoTracks.firstOrNull()?.let { videoTrack ->
                setFrameReadyCallback(videoTrack) {
                    cameraFailureHandler.removeCallbacks(videoFailureRunnable)
                    cameraFailureHandler.postDelayed(videoFailureRunnable, FAILURE_TIMEOUT)
                }
            }
            mediaStream.audioTracks.firstOrNull()?.let { audioTrack ->
                setFrameReadyCallback(audioTrack) {
                    microphoneFailureHandler.removeCallbacks(microphoneFailureRunnable)
                    microphoneFailureHandler.postDelayed(microphoneFailureRunnable, FAILURE_TIMEOUT)
                }
            }
        }
    }

    private fun observeChatServices() {
        chatServices.forEach { service ->
            Timber.d("Observing chat with mimetype: ${service.second}")
            service.first.observableChatMessages?.subscribe { messages ->
                messages.lastOrNull()?.takeIf { it.observableTimeStamp.value.time > joinedDate.time }?.let { last ->
                    Timber.d("Phenix message received: ${last.observableMessage.value}")
                    rawMessages.add(last.asPhenixMessage())
                    _messages.tryEmit(rawMessages.asCopy())
                }
            }.run { disposables.add(this) }
        }
    }

    private fun observeMemberCount(){
        roomService?.observableActiveRoom?.value?.observableEstimatedSize?.subscribe { size ->
            _memberCount.tryEmit(size)
        }.run { disposables.add(this) }
    }

    private fun disposeGoneMembers(members: List<PhenixCoreMember>) {
        rawMembers.forEach { member ->
            members.find { it.isThisMember(member.member.sessionId) }?.takeIf { it.isDisposable }?.let {
                Timber.d("Disposing gone member: $it")
                it.dispose()
            }
        }
    }

    private fun observeRoomMembers() {
        if (roomService == null) {
            _onError.tryEmit(PhenixError.JOIN_ROOM_FAILED.apply { data = roomConfiguration })
            return
        }
        roomService!!.observableActiveRoom.value.observableMembers.subscribe { members ->
            Timber.d("Received RAW members count: ${members.size}")
            val selfId = roomService!!.self.sessionId
            members.forEach { Timber.d("RAW Member: ${it.observableScreenName.value} ${it.sessionId == selfId}") }
            val memberList = mutableListOf(roomService!!.self.mapRoomMember(rawMembers, selfId, roomExpress, roomConfiguration))
            val mappedMembers = members.filterNot { it.sessionId == selfId }.mapTo(memberList) {
                it.mapRoomMember(rawMembers, selfId, roomExpress, roomConfiguration)
            }
            disposeGoneMembers(mappedMembers)
            rawMembers.clear()
            rawMembers.addAll(mappedMembers)
            if (roomConfiguration?.joinSilently == false) {
                subscribeRoomMembers()
            }
            _members.tryEmit(rawMembers.asPhenixMembers())
        }.run { disposables.add(this) }
    }

    fun release() {
        userMediaStream = null
        selfVideoRenderer = null
        selfPreviewImageView = null
        selfPreviewConfiguration = null
        roomConfiguration = null

        rawMembers.forEach { it.dispose() }
        chatServices.forEach { it.first.dispose() }
        rawMembers.clear()
        rawMessages.clear()
        rawRooms.clear()
        chatServices.clear()
    }
}
