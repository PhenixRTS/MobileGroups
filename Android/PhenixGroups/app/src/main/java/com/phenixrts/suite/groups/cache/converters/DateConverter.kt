/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.cache.converters

import androidx.room.TypeConverter
import java.util.*

class DateConverter {

    @TypeConverter
    fun toDate(dateLong:Long): Date {
        return Date(dateLong)
    }

    @TypeConverter
    fun fromDate(date: Date): Long{
        return date.time
    }
}
