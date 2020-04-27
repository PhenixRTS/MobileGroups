/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.cache

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.phenixrts.suite.groups.cache.converters.DateConverter
import com.phenixrts.suite.groups.cache.dao.CacheDao
import com.phenixrts.suite.groups.cache.entities.RoomInfoItem

@Database(
    entities = [RoomInfoItem::class],
    version = 2,
    exportSchema = false
)
@TypeConverters(DateConverter::class)
abstract class CacheProvider : RoomDatabase() {

    abstract fun cacheDao(): CacheDao

}
