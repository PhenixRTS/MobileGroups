/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.phenixcore.repositories.channel

import android.view.SurfaceView
import android.widget.ImageView
import com.phenixrts.express.ChannelExpress
import com.phenixrts.express.PCastExpress
import com.phenixrts.suite.phenixcore.common.ConsumableSharedFlow
import com.phenixrts.suite.phenixcore.common.asPhenixChannels
import com.phenixrts.suite.phenixcore.common.launchIO
import com.phenixrts.suite.phenixcore.repositories.channel.models.PhenixCoreChannel
import com.phenixrts.suite.phenixcore.repositories.models.*
import kotlinx.coroutines.flow.*
import timber.log.Timber

internal class PhenixChannelRepository(
    private val pCastExpress: PCastExpress,
    private val channelExpress: ChannelExpress,
    private val configuration: PhenixConfiguration
) {
    private val rawChannels = mutableListOf<PhenixCoreChannel>()

    private val _onError = ConsumableSharedFlow<PhenixError>()
    private val _onEvent = ConsumableSharedFlow<PhenixEvent>()
    private val _channels = ConsumableSharedFlow<List<PhenixChannel>>(canReplay = true)

    val channels = _channels.asSharedFlow()
    val onError = _onError.asSharedFlow()
    val onEvent = _onEvent.asSharedFlow()

    fun joinAllChannels(channelAliases: List<String>, streamIDs: List<String>) {
        if (configuration.channelTokens.isNotEmpty() && configuration.channelTokens.size != channelAliases.size) {
            _onError.tryEmit(PhenixError.JOIN_ROOM_FAILED)
            return
        }
        channelAliases.forEachIndexed { index, channelAlias ->
            if (rawChannels.any { it.channelAlias == channelAlias }) return
            val channel = PhenixCoreChannel(pCastExpress, channelExpress, configuration, channelAlias = channelAlias)
            Timber.d("Joining channel: $channelAlias")
            channel.join(
                PhenixChannelConfiguration(
                    channelAlias = channelAlias,
                    streamToken = configuration.channelTokens.getOrNull(index) ?: configuration.edgeToken,
                    publishToken = configuration.publishToken ?: configuration.edgeToken
                )
            )
            launchIO { channel.onUpdated.collect { _channels.tryEmit(rawChannels.asPhenixChannels()) } }
            launchIO { channel.onError.collect { _onError.tryEmit(it) } }
            rawChannels.add(channel)
        }
        streamIDs.forEachIndexed { index, streamID ->
            if (rawChannels.any { it.streamID == streamID }) return
            val channel = PhenixCoreChannel(pCastExpress, channelExpress, configuration, streamID = streamID)
            Timber.d("Joining channel: $streamID")
            channel.join(
                PhenixChannelConfiguration(
                    channelID = streamID,
                    streamToken = configuration.channelTokens.getOrNull(index) ?: configuration.edgeToken,
                    publishToken = configuration.publishToken ?: configuration.edgeToken
                )
            )
            launchIO { channel.onUpdated.collect { _channels.tryEmit(rawChannels.asPhenixChannels()) } }
            launchIO { channel.onError.collect { _onError.tryEmit(it) } }
            rawChannels.add(channel)
        }
        _channels.tryEmit(rawChannels.asPhenixChannels())
    }

    fun joinChannel(config: PhenixChannelConfiguration) {
        val channelAlias = config.channelAlias
        if (rawChannels.any { it.channelAlias == channelAlias }) return
        val channel = PhenixCoreChannel(pCastExpress, channelExpress, configuration, channelAlias)
        channel.join(config)
        launchIO { channel.onUpdated.collect { _channels.tryEmit(rawChannels.asPhenixChannels()) } }
        launchIO { channel.onError.collect { _onError.tryEmit(it) } }
        rawChannels.add(channel)
        _channels.tryEmit(rawChannels.asPhenixChannels())
    }

    fun selectChannel(channelAlias: String, isSelected: Boolean) {
        rawChannels.find { it.channelAlias == channelAlias }?.selectChannel(isSelected)
    }

    fun renderOnSurface(channelAlias: String, surfaceView: SurfaceView?) {
        rawChannels.find { it.channelAlias == channelAlias }?.renderOnSurface(surfaceView)
    }

    fun renderOnImage(channelAlias: String, imageView: ImageView?, configuration: PhenixFrameReadyConfiguration?) {
        rawChannels.find { it.channelAlias == channelAlias }?.renderOnImage(imageView, configuration)
    }

    fun setAudioEnabled(channelAlias: String, enabled: Boolean) {
        rawChannels.find { it.channelAlias == channelAlias }?.setAudioEnabled(enabled)
    }

    fun createTimeShift(channelAlias: String, timestamp: Long) {
        rawChannels.find { it.channelAlias == channelAlias }?.createTimeShift(timestamp)
    }

    fun startTimeShift(channelAlias: String, duration: Long) {
        rawChannels.find { it.channelAlias == channelAlias }?.startTimeShift(duration)
    }

    fun seekTimeShift(channelAlias: String, offset: Long) {
        rawChannels.find { it.channelAlias == channelAlias }?.seekTimeShift(offset)
    }

    fun playTimeShift(channelAlias: String) {
        rawChannels.find { it.channelAlias == channelAlias }?.playTimeShift()
    }

    fun pauseTimeShift(channelAlias: String) {
        rawChannels.find { it.channelAlias == channelAlias }?.pauseTimeShift()
    }

    fun stopTimeShift(channelAlias: String) {
        rawChannels.find { it.channelAlias == channelAlias }?.stopTimeShift()
    }

    fun limitBandwidth(channelAlias: String, bandwidth: Long) {
        rawChannels.find { it.channelAlias == channelAlias }?.limitBandwidth(bandwidth)
    }

    fun releaseBandwidthLimiter(channelAlias: String) {
        rawChannels.find { it.channelAlias == channelAlias }?.releaseBandwidthLimiter()
    }

    fun subscribeForMessages(channelAlias: String) {
        rawChannels.find { it.channelAlias == channelAlias }?.subscribeForMessages()
    }

    fun release() {
        rawChannels.forEach { it.release() }
        rawChannels.clear()
    }

}
