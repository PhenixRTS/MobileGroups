/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.injection

import androidx.lifecycle.MutableLiveData
import androidx.room.Room
import com.phenixrts.common.RequestStatus
import com.phenixrts.environment.android.AndroidContext
import com.phenixrts.express.PCastExpressFactory
import com.phenixrts.express.RoomExpressFactory
import com.phenixrts.suite.groups.BuildConfig
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.cache.PreferenceProvider
import com.phenixrts.suite.groups.common.FileWriterDebugTree
import com.phenixrts.suite.groups.models.DeepLinkModel
import com.phenixrts.suite.groups.models.RoomStatus
import com.phenixrts.suite.groups.receivers.CellularStateReceiver
import com.phenixrts.suite.groups.repository.RoomExpressRepository
import com.phenixrts.suite.groups.repository.UserMediaRepository
import dagger.Module
import dagger.Provides
import timber.log.Timber
import javax.inject.Singleton

@Module
class InjectionModule(private val context: GroupsApplication) {

    private var roomExpressRepository: RoomExpressRepository? = null
    private var userMediaRepository: UserMediaRepository? = null
    private var pCastUrl = BuildConfig.PCAST_URL
    private var backendUrl = BuildConfig.BACKEND_URL

    fun hasUrisChanged(deepLinkModel: DeepLinkModel): Boolean {
        Timber.d("Updating Room Express uris: $deepLinkModel")
        var changed = false
        if (deepLinkModel.uri != null && pCastUrl != deepLinkModel.uri) {
            pCastUrl = deepLinkModel.uri
            roomExpressRepository = null
            userMediaRepository = null
            changed = true
        }
        if (deepLinkModel.backend != null && backendUrl != deepLinkModel.backend) {
            backendUrl = deepLinkModel.backend
            roomExpressRepository = null
            userMediaRepository = null
            changed = true
        }
        return changed
    }

    @Provides
    fun provideRoomExpressRepository(cacheProvider: CacheProvider): RoomExpressRepository {
        if (roomExpressRepository == null) {
            Timber.d("Create Room Express Singleton")
            val roomStatus = MutableLiveData<RoomStatus>()
            roomStatus.value = RoomStatus(RequestStatus.OK, "")
            AndroidContext.setContext(context)
            val pcastExpressOptions = PCastExpressFactory.createPCastExpressOptionsBuilder()
                .withBackendUri(backendUrl)
                .withPCastUri(pCastUrl)
                .withUnrecoverableErrorCallback { status: RequestStatus, description: String ->
                    Timber.e("Unrecoverable error in PhenixSDK. Error status: [$status]. Description: [$description]")
                    roomStatus.value = RoomStatus(status, description)
                }
                .withMinimumConsoleLogLevel("info")
                .buildPCastExpressOptions()

            val roomExpressOptions = RoomExpressFactory.createRoomExpressOptionsBuilder()
                .withPCastExpressOptions(pcastExpressOptions)
                .buildRoomExpressOptions()
            roomExpressRepository = RoomExpressRepository(
                cacheProvider,
                RoomExpressFactory.createRoomExpress(roomExpressOptions),
                roomStatus
            )
        }
        return roomExpressRepository!!
    }

    @Provides
    fun provideUserMediaRepository(roomExpressRepository: RoomExpressRepository): UserMediaRepository {
        if (userMediaRepository == null) {
            userMediaRepository = UserMediaRepository(roomExpressRepository.roomExpress)
        }
        return userMediaRepository!!
    }

    @Provides
    @Singleton
    fun provideCacheProvider(): CacheProvider
            = Room.databaseBuilder(context, CacheProvider::class.java, "phenix_database").build()

    @Provides
    @Singleton
    fun providePreferencesProvider(): PreferenceProvider = PreferenceProvider(context)

    @Provides
    @Singleton
    fun provideCellularStateReceiver(): CellularStateReceiver = CellularStateReceiver(context)

    @Provides
    @Singleton
    fun provideFileWriterDebugTree(): FileWriterDebugTree = FileWriterDebugTree(context)

}
