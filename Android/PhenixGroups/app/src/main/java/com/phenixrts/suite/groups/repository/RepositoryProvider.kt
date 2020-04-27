/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

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
import com.phenixrts.suite.groups.common.extensions.launchMain
import com.phenixrts.suite.groups.models.RoomExpressConfiguration
import com.phenixrts.suite.groups.models.RoomStatus
import kotlinx.coroutines.delay
import timber.log.Timber
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class RepositoryProvider(
    private val context: GroupsApplication,
    private val cacheProvider: CacheProvider
) {

    private var roomExpressRepository: RoomExpressRepository? = null
    private var userMediaRepository: UserMediaRepository? = null
    private var expressConfiguration: RoomExpressConfiguration = RoomExpressConfiguration()
    var roomExpress: RoomExpress? = null
    val onRoomStatusChanged = MutableLiveData<RoomStatus>().apply { value = RoomStatus(RequestStatus.OK) }

    private suspend fun initializeRoomExpress() {
        Timber.d("Creating Room Express with configuration: $expressConfiguration")
        val roomStatus = MutableLiveData<RoomStatus>()
        AndroidContext.setContext(context)
        val pcastExpressOptions = PCastExpressFactory.createPCastExpressOptionsBuilder()
            .withBackendUri(expressConfiguration.backend)
            .withPCastUri(expressConfiguration.uri)
            .withUnrecoverableErrorCallback { status: RequestStatus, description: String ->
                Timber.e("Unrecoverable error in PhenixSDK. Error status: [$status]. Description: [$description]")
                roomStatus.value = RoomStatus(status, description)
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

    suspend fun reinitializeRoomExpress(configuration: RoomExpressConfiguration) {
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

    suspend fun collectLogMessages(): String = suspendCoroutine { continuation ->
        roomExpress?.pCastExpress?.pCast?.collectLogMessages { _, _, messages ->
            continuation.resume(messages)
        } ?: continuation.resume("")
    }

    fun hasConfigurationChanged(configuration: RoomExpressConfiguration): Boolean = expressConfiguration != configuration

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

    private companion object {
        private const val REINITIALIZATION_DELAY = 1000L
    }
}
