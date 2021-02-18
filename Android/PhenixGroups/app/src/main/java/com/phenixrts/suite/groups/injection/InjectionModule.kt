/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.injection

import androidx.room.Room
import com.phenixrts.suite.groups.BuildConfig
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.cache.PreferenceProvider
import com.phenixrts.suite.phenixcommon.common.FileWriterDebugTree
import com.phenixrts.suite.groups.receivers.CellularStateReceiver
import com.phenixrts.suite.groups.repository.RepositoryProvider
import dagger.Module
import dagger.Provides
import javax.inject.Singleton

private const val TIMBER_TAG = "PhenixApp"

@Module
class InjectionModule(private val context: GroupsApplication) {

    @Singleton
    @Provides
    fun provideRepositoryProvider(cacheProvider: CacheProvider): RepositoryProvider
            = RepositoryProvider(context, cacheProvider)

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

    @Provides
    @Singleton
    fun provideFileWriterDebugTree(): FileWriterDebugTree =
        FileWriterDebugTree(context, TIMBER_TAG, "${BuildConfig.APPLICATION_ID}.provider")

}
