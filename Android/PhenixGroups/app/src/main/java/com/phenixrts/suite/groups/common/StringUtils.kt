/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common

import java.text.SimpleDateFormat
import java.util.*

fun getRoomCode(): String {
    return ('a' .. 'z').map { it }.shuffled().let {
        it.subList(0, 3).joinToString(separator = "").plus("-") +
                it.subList(3, 7).joinToString(separator = "").plus("-") +
                it.subList(7, 10).joinToString(separator = "")
    }
}

fun getFormattedDate(date: Date?): String = date?.let {
    SimpleDateFormat("HH:mm", Locale.getDefault()).format(date)
} ?: ""
