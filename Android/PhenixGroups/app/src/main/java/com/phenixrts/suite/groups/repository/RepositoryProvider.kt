/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import android.media.AudioManager
import androidx.lifecycle.MutableLiveData
import com.phenixrts.common.RequestStatus
import com.phenixrts.environment.android.AndroidContext
import com.phenixrts.express.PCastExpressFactory
import com.phenixrts.express.RoomExpress
import com.phenixrts.express.RoomExpressFactory
import com.phenixrts.pcast.UserMediaStream
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.phenixcommon.common.launchMain
import com.phenixrts.suite.groups.models.RoomStatus
import com.phenixrts.suite.phenixdeeplink.models.PhenixConfiguration
import kotlinx.coroutines.delay
import timber.log.Timber
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

private const val REINITIALIZATION_DELAY = 1000L

class RepositoryProvider(
    private val context: GroupsApplication,
    private val cacheProvider: CacheProvider
) {

    private var roomExpressRepository: RoomExpressRepository? = null
    private var userMediaRepository: UserMediaRepository? = null
    private var expressConfiguration = PhenixConfiguration()
    var roomExpress: RoomExpress? = null
    val onRoomStatusChanged = MutableLiveData<RoomStatus>().apply { value = RoomStatus(RequestStatus.OK) }

    private suspend fun initializeRoomExpress() {
        Timber.d("Creating Room Express with configuration: $expressConfiguration")
        val audioManager = context.getSystemService(android.content.Context.AUDIO_SERVICE) as AudioManager
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        audioManager.isSpeakerphoneOn = true

        AndroidContext.setContext(context)
        val pcastExpressOptions = PCastExpressFactory.createPCastExpressOptionsBuilder()
            .withBackendUri(expressConfiguration.backend)
            .withPCastUri(expressConfiguration.uri)
            .withUnrecoverableErrorCallback { status: RequestStatus, description: String ->
                Timber.e("Unrecoverable error in PhenixSDK. Error status: [$status]. Description: [$description]")
                onRoomStatusChanged.value = RoomStatus(status, description)
            }
            .withMinimumConsoleLogLevel("info")
            .buildPCastExpressOptions()
        val roomExpressOptions = RoomExpressFactory.createRoomExpressOptionsBuilder()
            .withPCastExpressOptions(pcastExpressOptions)
            .buildRoomExpressOptions()
        RoomExpressFactory.createRoomExpress(roomExpressOptions)?.let { express ->
            roomExpress = express
            roomExpressRepository = RoomExpressRepository(cacheProvider, express, getCurrentConfiguration())
            userMediaRepository = UserMediaRepository(express)
            userMediaRepository?.waitForUserStream().let { mediaStatus ->
                Timber.d("User media repository created: $mediaStatus")
                if (mediaStatus == RequestStatus.FAILED) {
                    onRoomStatusChanged.value = RoomStatus(RequestStatus.FAILED,
                        context.getString(R.string.err_user_media_not_initialized))
                }
            }
        }
    }

    suspend fun setupRoomExpress(configuration: PhenixConfiguration) {
        if (hasConfigurationChanged(configuration)) {
            Timber.d("Room Express configuration has changed: $configuration")
            expressConfiguration = configuration
            roomExpressRepository?.dispose()
            userMediaRepository?.dispose()
            roomExpressRepository = null
            userMediaRepository = null
            roomExpress = null
            Timber.d("Room Express disposed")
            delay(REINITIALIZATION_DELAY)
            initializeRoomExpress()
        }
    }

    suspend fun waitForPCast(): Unit = suspendCoroutine {
        launchMain {
            Timber.d("Waiting for pCast")
            if (roomExpressRepository == null) {
                initializeRoomExpress()
            }
            roomExpressRepository?.waitForPCast()
            it.resume(Unit)
        }
    }

    private fun hasConfigurationChanged(configuration: PhenixConfiguration): Boolean = expressConfiguration != configuration

    fun isRoomExpressInitialized(): Boolean = roomExpress != null

    fun getRoomExpressRepository(): RoomExpressRepository? {
        if (roomExpressRepository == null) {
            onRoomStatusChanged.value = RoomStatus(RequestStatus.FAILED,
                context.getString(R.string.err_room_express_not_initialized))
        }
        return roomExpressRepository
    }

    fun getUserMediaRepository(): UserMediaRepository? {
        if (userMediaRepository == null) {
            onRoomStatusChanged.value = RoomStatus(RequestStatus.FAILED,
                context.getString(R.string.err_user_media_not_initialized))
        }
        return userMediaRepository
    }

    fun getUserMediaStream(): UserMediaStream? {
        if (getUserMediaRepository()?.userMediaStream == null) {
            onRoomStatusChanged.value = RoomStatus(RequestStatus.FAILED,
                context.getString(R.string.err_user_media_not_initialized))
        }
        return getUserMediaRepository()?.userMediaStream
    }

    fun getCurrentConfiguration() = expressConfiguration

}
