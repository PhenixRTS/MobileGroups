/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common

import com.phenixrts.suite.groups.common.extensions.isLongerThanDay
import java.text.SimpleDateFormat
import java.util.*

fun getRoomCode(): String {
    return ('a' .. 'z').map { it }.shuffled().let {
        it.subList(0, 3).joinToString(separator = "").plus("-") +
                it.subList(3, 7).joinToString(separator = "").plus("-") +
                it.subList(7, 10).joinToString(separator = "")
    }
}

fun getFormattedDate(date: Date?): String = date?.let { currentDate ->
    val pattern = if (currentDate.isLongerThanDay()) "dd.MM HH:mm" else "HH:mm"
    SimpleDateFormat(pattern, Locale.getDefault()).format(currentDate)
} ?: ""
