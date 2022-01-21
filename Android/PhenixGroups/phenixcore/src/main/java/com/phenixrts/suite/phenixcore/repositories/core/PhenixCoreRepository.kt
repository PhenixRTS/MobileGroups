/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.phenixcore.repositories.core

import android.content.Context
import android.view.SurfaceView
import android.widget.ImageView
import com.phenixrts.common.RequestStatus
import com.phenixrts.environment.android.AndroidContext
import com.phenixrts.express.*
import com.phenixrts.room.MemberRole
import com.phenixrts.room.MemberState
import com.phenixrts.suite.phenixcore.BuildConfig
import com.phenixrts.suite.phenixcore.common.ConsumableSharedFlow
import com.phenixrts.suite.phenixcore.common.FileWriterDebugTree
import com.phenixrts.suite.phenixcore.common.launchIO
import com.phenixrts.suite.phenixcore.repositories.channel.PhenixChannelRepository
import com.phenixrts.suite.phenixcore.repositories.core.common.PHENIX_LOG_LEVEL
import com.phenixrts.suite.phenixcore.repositories.core.models.PhenixCoreState
import com.phenixrts.suite.phenixcore.repositories.models.*
import com.phenixrts.suite.phenixcore.repositories.room.PhenixRoomRepository
import kotlinx.coroutines.flow.*
import timber.log.Timber

internal class PhenixCoreRepository(
    private val context: Context,
    private val debugTree: FileWriterDebugTree
) {

    private var configuration = PhenixConfiguration()
    private var roomExpress: RoomExpress? = null
    private var channelRepository: PhenixChannelRepository? = null
    private var roomRepository: PhenixRoomRepository? = null

    private var _phenixState = PhenixCoreState.NOT_INITIALIZED
    private val _onError = ConsumableSharedFlow<PhenixError>()
    private val _onEvent = ConsumableSharedFlow<PhenixEvent>()
    private val _channels = ConsumableSharedFlow<List<PhenixChannel>>(canReplay = true)
    private val _messages = ConsumableSharedFlow<List<PhenixMessage>>(canReplay = true)
    private val _logMessages = ConsumableSharedFlow<String>()
    private val _members = ConsumableSharedFlow<List<PhenixMember>>(canReplay = true)
    private val _rooms = ConsumableSharedFlow<List<PhenixRoom>>(canReplay = true)
    private var _memberCount = ConsumableSharedFlow<Long>(canReplay = true)

    val onError = _onError.asSharedFlow()
    val onEvent = _onEvent.asSharedFlow()
    val channels = _channels.asSharedFlow()
    val members = _members.asSharedFlow()
    val messages = _messages.asSharedFlow()
    val logMessages = _logMessages.asSharedFlow()
    val rooms = _rooms.asSharedFlow()
    val memberCount = _memberCount.asSharedFlow()

    val isPhenixInitializing get() = _phenixState == PhenixCoreState.INITIALIZING
    val isPhenixInitialized get() = _phenixState == PhenixCoreState.INITIALIZED

    fun init(config: PhenixConfiguration?) {
        _phenixState = PhenixCoreState.INITIALIZING
        AndroidContext.setContext(context)
        if (BuildConfig.DEBUG) {
            Timber.plant(debugTree)
        }
        if (config != null) {
            configuration = config
        }
        Timber.d("Initializing Phenix Core with configuration: $configuration")
        AndroidContext.setContext(context)
        var pcastBuilder = PCastExpressFactory.createPCastExpressOptionsBuilder()
            .withMinimumConsoleLogLevel(PHENIX_LOG_LEVEL)
            .withPCastUri(configuration.uri)
            .withUnrecoverableErrorCallback { status: RequestStatus, description: String ->
                Timber.e("Failed to initialize Phenix Core: $status, $description with configuration: $configuration")
                _onError.tryEmit(PhenixError.FAILED_TO_INITIALIZE)
            }
        pcastBuilder = if (!configuration.authToken.isNullOrBlank()) {
            pcastBuilder.withAuthenticationToken(configuration.authToken)
        } else if (!configuration.edgeToken.isNullOrBlank()) {
            pcastBuilder.withAuthenticationToken(configuration.edgeToken)
        } else {
            pcastBuilder.withBackendUri(configuration.backend)
        }
        val roomExpressOptions = RoomExpressFactory.createRoomExpressOptionsBuilder()
            .withPCastExpressOptions(pcastBuilder.buildPCastExpressOptions())
            .buildRoomExpressOptions()

        val channelExpressOptions = ChannelExpressFactory.createChannelExpressOptionsBuilder()
            .withRoomExpressOptions(roomExpressOptions)
            .buildChannelExpressOptions()

        ChannelExpressFactory.createChannelExpress(channelExpressOptions)?.let { express ->
            express.roomExpress?.pCastExpress?.waitForOnline {
                Timber.d("Phenix Core initialized")
                roomExpress = express.roomExpress
                channelRepository = PhenixChannelRepository(express.roomExpress!!.pCastExpress, express, configuration)
                roomRepository = PhenixRoomRepository(express.roomExpress, configuration)
                _phenixState = PhenixCoreState.INITIALIZED
                _onEvent.tryEmit(PhenixEvent.PHENIX_CORE_INITIALIZED)

                launchIO { channelRepository?.onError?.collect { _onError.tryEmit(it) } }
                launchIO { channelRepository?.onEvent?.collect { _onEvent.tryEmit(it) } }
                launchIO { channelRepository?.channels?.collect { _channels.tryEmit(it) } }

                launchIO { roomRepository?.onError?.collect { _onError.tryEmit(it) } }
                launchIO { roomRepository?.onEvent?.collect { _onEvent.tryEmit(it) } }
                launchIO { roomRepository?.members?.collect { _members.tryEmit(it) } }
                launchIO { roomRepository?.messages?.collect { _messages.tryEmit(it) } }
                launchIO { roomRepository?.rooms?.collect { _rooms.tryEmit(it) } }
                launchIO { roomRepository?.memberCount?.collect { _memberCount.tryEmit(it) } }
            }
        } ?: run {
            Timber.e("Failed to initialize Phenix Core")
            _phenixState = PhenixCoreState.NOT_INITIALIZED
            _onError.tryEmit(PhenixError.FAILED_TO_INITIALIZE)
        }
    }

    fun joinAllChannels(channelAliases: List<String>, streamIDs: List<String>) =
        channelRepository?.joinAllChannels(channelAliases, streamIDs)

    fun joinChannel(config: PhenixChannelConfiguration) =
        channelRepository?.joinChannel(config)

    fun selectChannel(alias: String, isSelected: Boolean) =
        channelRepository?.selectChannel(alias, isSelected)

    fun flipCamera() = roomRepository?.flipCamera()

    fun renderOnSurface(alias: String, surfaceView: SurfaceView?) {
        channelRepository?.renderOnSurface(alias, surfaceView)
        roomRepository?.renderOnSurface(alias, surfaceView)
    }

    fun renderOnImage(alias: String, imageView: ImageView?, configuration: PhenixFrameReadyConfiguration?) {
        channelRepository?.renderOnImage(alias, imageView, configuration)
        roomRepository?.renderOnImage(alias, imageView, configuration)
    }

    fun previewOnSurface(surfaceView: SurfaceView?) =
        roomRepository?.previewOnSurface(surfaceView)

    fun previewOnImage(imageView: ImageView?, configuration: PhenixFrameReadyConfiguration?) =
        roomRepository?.previewOnImage(imageView, configuration)

    fun createTimeShift(alias: String, timestamp: Long) =
        channelRepository?.createTimeShift(alias, timestamp)

    fun seekTimeShift(alias: String, offset: Long) =
        channelRepository?.seekTimeShift(alias, offset)

    fun playTimeShift(alias: String) =
        channelRepository?.playTimeShift(alias)

    fun startTimeShift(alias: String, duration: Long) =
        channelRepository?.startTimeShift(alias, duration)

    fun pauseTimeShift(alias: String) =
        channelRepository?.pauseTimeShift(alias)

    fun stopTimeShift(alias: String) =
        channelRepository?.stopTimeShift(alias)

    fun limitBandwidth(alias: String, bandwidth: Long) =
        channelRepository?.limitBandwidth(alias, bandwidth)

    fun releaseBandwidthLimiter(alias: String) =
        channelRepository?.releaseBandwidthLimiter(alias)

    fun subscribeForMessages(alias: String) =
        channelRepository?.subscribeForMessages(alias)

    fun setAudioEnabled(alias: String, enabled: Boolean) {
        channelRepository?.setAudioEnabled(alias, enabled)
        roomRepository?.setAudioEnabled(alias, enabled)
    }

    fun setSelfAudioEnabled(enabled: Boolean) =
        roomRepository?.setSelfAudioEnabled(enabled)

    fun setVideoEnabled(alias: String, enabled: Boolean) =
        roomRepository?.setVideoEnabled(alias, enabled)

    fun setSelfVideoEnabled(enabled: Boolean) =
        roomRepository?.setSelfVideoEnabled(enabled)

    fun joinRoom(configuration: PhenixRoomConfiguration) =
        roomRepository?.joinRoom(configuration)

    fun createRoom(configuration: PhenixRoomConfiguration) =
        roomRepository?.createRoom(configuration)

    fun stopPublishing() = roomRepository?.stopPublishing()

    fun leaveRoom() = roomRepository?.leaveRoom()

    fun updateMember(memberId: String, role: MemberRole?, active: MemberState?, name: String?) =
        roomRepository?.updateMember(memberId, role, active, name)

    fun setAudioLevel(memberId: String, level: Float) =
        roomRepository?.setAudioLevel(memberId, level)

    fun sendMessage(message: String, mimeType: String) =
        roomRepository?.sendMessage(message, mimeType)

    fun selectMember(memberId: String, isSelected: Boolean) =
        roomRepository?.selectMember(memberId, isSelected)

    fun publishToRoom(configuration: PhenixRoomConfiguration) =
        roomRepository?.publishToRoom(configuration)

    fun subscribeToRoom() = roomRepository?.subscribeRoomMembers()

    fun collectLogs() {
        roomExpress?.pCastExpress?.pCast?.collectLogMessages { _, _, messages ->
            _logMessages.tryEmit(messages)
        }
    }

    fun release() {
        roomExpress?.dispose()
        channelRepository?.release()
        roomRepository?.release()

        configuration = PhenixConfiguration()
        roomExpress = null
        channelRepository = null
        roomRepository = null
        _phenixState = PhenixCoreState.NOT_INITIALIZED
    }

}
