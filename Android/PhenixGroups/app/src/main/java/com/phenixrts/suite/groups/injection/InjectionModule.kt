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
import com.phenixrts.suite.groups.models.RoomStatus
import com.phenixrts.suite.groups.phenix.RoomExpressRepository
import dagger.Module
import dagger.Provides
import timber.log.Timber
import javax.inject.Singleton

@Module
class InjectionModule(private val context: GroupsApplication) {

    @Provides
    @Singleton
    fun provideRoomExpressRepository(cacheProvider: CacheProvider): RoomExpressRepository {
        Timber.d("Create Room Express Singleton")
        val roomStatus = MutableLiveData<RoomStatus>()
        roomStatus.value = RoomStatus(RequestStatus.OK, "")
        AndroidContext.setContext(context)
        val pcastExpressOptions = PCastExpressFactory.createPCastExpressOptionsBuilder()
            .withBackendUri(BuildConfig.BACKEND_URL)
            .withPCastUri(BuildConfig.PCAST_URL)
            .withUnrecoverableErrorCallback { status: RequestStatus, description: String ->
                Timber.e(
                    "Unrecoverable error in PhenixSDK. " +
                            "Error status: [$status]. " +
                            "Description: [$description]"
                )
                roomStatus.value = RoomStatus(status, description)
            }
            .buildPCastExpressOptions()

        val roomExpressOptions = RoomExpressFactory.createRoomExpressOptionsBuilder()
            .withPCastExpressOptions(pcastExpressOptions)
            .buildRoomExpressOptions()
        return RoomExpressRepository(cacheProvider, RoomExpressFactory.createRoomExpress(roomExpressOptions), roomStatus)
    }

    @Provides
    @Singleton
    fun provideCacheProvider(): CacheProvider {
        return Room.databaseBuilder(
            context,
            CacheProvider::class.java,
            "phenix_database"
        ).build()
    }
}
