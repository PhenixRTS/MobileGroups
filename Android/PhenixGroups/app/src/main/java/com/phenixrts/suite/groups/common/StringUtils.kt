/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common

import android.os.Process
import android.util.Log
import com.phenixrts.suite.groups.common.extensions.isLongerThanDay
import java.text.SimpleDateFormat
import java.util.*

private const val DATE_FORMAT = "MM-dd HH:mm:ss.SSS"
private val LEVEL_NAMES = arrayOf("F", "?", "T", "D", "I", "W", "E")

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

fun getFormattedLogMessage(tag: String?, level: Int, message: String?, e: Throwable?): String {
    val id: Long = try {
        Process.myTid().toLong()
    } catch (e1: RuntimeException) {
        Thread.currentThread().id
    }
    val builder: StringBuilder = StringBuilder()
        .append(SimpleDateFormat(DATE_FORMAT, Locale.getDefault()).format(Date()))
        .append(' ').append(id)
        .append(' ').append(LEVEL_NAMES[level])
        .append(' ').append(tag)
        .append(' ').append(message)
    if (e != null) {
        builder.append(": throwable=").append(Log.getStackTraceString(e))
    }
    return builder.toString()
}
