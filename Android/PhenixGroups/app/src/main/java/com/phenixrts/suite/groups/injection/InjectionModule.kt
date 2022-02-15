/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.injection

import androidx.room.Room
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.cache.PreferenceProvider
import com.phenixrts.suite.groups.receivers.CellularStateReceiver
import com.phenixrts.suite.phenixcore.PhenixCore
import dagger.Module
import dagger.Provides
import javax.inject.Singleton

@Module
class InjectionModule(private val context: GroupsApplication) {

    @Singleton
    @Provides
    fun providePhenixCore() = PhenixCore(context)

    @Provides
    @Singleton
    fun provideCacheProvider(): CacheProvider = Room.databaseBuilder(context, CacheProvider::class.java, "phenix_database")
        .fallbackToDestructiveMigration().build()

    @Provides
    @Singleton
    fun providePreferencesProvider(): PreferenceProvider = PreferenceProvider(context)

    @Provides
    @Singleton
    fun provideCellularStateReceiver(): CellularStateReceiver = CellularStateReceiver(context)

}
