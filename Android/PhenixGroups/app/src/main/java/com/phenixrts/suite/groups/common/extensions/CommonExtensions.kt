/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.extensions

import androidx.lifecycle.MutableLiveData
import com.phenixrts.chat.ChatMessage
import com.phenixrts.room.Member
import com.phenixrts.suite.groups.BuildConfig
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.databinding.RowMemberItemBinding
import com.phenixrts.suite.groups.models.RoomMember
import com.phenixrts.suite.groups.models.RoomMessage
import java.util.*

const val SECOND_MILLIS = 1000L
const val MINUTE_MILLIS = SECOND_MILLIS * 60L
const val HOUR_MILLIS = MINUTE_MILLIS * 60L
const val DAY_MILLIS = HOUR_MILLIS * 24L
const val MONTH_MILLIS = DAY_MILLIS * 30L
const val YEAR_MILLIS = MONTH_MILLIS * 12L

fun MutableList<RoomMessage>.addUnique(messages: Array<ChatMessage>, selfName: String, dateRoomLeft: Date, isViewingChat: Boolean) {
    messages.forEach {message ->
        if (this.find { it.message.messageId == message.messageId } == null) {
            val isSelf = selfName == message.observableFrom.value.observableScreenName.value
            val isRead = isViewingChat || message.observableTimeStamp.value.time < dateRoomLeft.time
            this.add(RoomMessage(message, isSelf, isRead))
        }
    }
    this.sortBy { it.message.observableTimeStamp.value }
}

fun MutableLiveData<Boolean>.isTrue(default: Boolean = false) = if (value != null) value == true else default

fun MutableLiveData<Boolean>.isFalse(default: Boolean = true) = if (value != null) value == false else default

fun MutableLiveData<Unit>.call() {
    value = Unit
}

fun MutableLiveData<RoomMember>.call(roomMember: RoomMember) {
    value = roomMember
}

fun MutableLiveData<List<RoomMessage>>.refresh() {
    value = this.value
}

fun RowMemberItemBinding.refresh() {
    this.member = this.member
}

fun Member.mapRoomMember(members: List<RoomMember>?, selfSessionId: String) =
    members?.find { it.isThisMember(this@mapRoomMember.sessionId) }?.apply {
        member = this@mapRoomMember
        isSelf = this@mapRoomMember.sessionId == selfSessionId
    } ?: RoomMember(this, this@mapRoomMember.sessionId == selfSessionId)

fun Calendar.expirationDate(): Date {
    add(Calendar.DAY_OF_MONTH, - BuildConfig.EXPIRATION_DAYS)
    return time
}

fun Date.elapsedTime(): String {
    val currentTime = System.currentTimeMillis()

    val seconds = time / SECOND_MILLIS
    val minutes = time / MINUTE_MILLIS
    val hours = time / HOUR_MILLIS
    val days = time / DAY_MILLIS
    val months = time / MONTH_MILLIS
    val years = time / YEAR_MILLIS
    val currentSeconds = currentTime / SECOND_MILLIS
    val currentMinutes = currentTime / MINUTE_MILLIS
    val currentHours = currentTime / HOUR_MILLIS
    val currentDays = currentTime / DAY_MILLIS
    val currentMonths = currentTime / MONTH_MILLIS
    val currentYears = currentTime / YEAR_MILLIS

    val secondsElapsed = currentSeconds - seconds
    val minutesElapsed = if (secondsElapsed > 59) currentMinutes - minutes else 0
    val hoursElapsed = if (minutesElapsed > 59) currentHours - hours else 0
    val daysElapsed = if (hoursElapsed > 23) currentDays - days else 0
    val monthsElapsed = if (daysElapsed > 29) currentMonths - months else 0
    val yearsElapsed = if (monthsElapsed > 11) currentYears - years else 0

    return when {
        yearsElapsed > 0 -> {
            GroupsApplication.getString(
                if (yearsElapsed == 1L) R.string.chat_time_year
                else R.string.chat_time_years,
                yearsElapsed.toString()
            )
        }
        monthsElapsed > 0 -> {
            GroupsApplication.getString(
                if (monthsElapsed == 1L) R.string.chat_time_month
                else R.string.chat_time_months,
                monthsElapsed.toString()
            )
        }
        daysElapsed > 0 -> {
            GroupsApplication.getString(
                if (daysElapsed == 1L) R.string.chat_time_day
                else R.string.chat_time_days,
                daysElapsed.toString()
            )
        }
        hoursElapsed > 0 -> {
            GroupsApplication.getString(
                if (hoursElapsed == 1L) R.string.chat_time_hour
                else R.string.chat_time_hours,
                hoursElapsed.toString()
            )
        }
        minutesElapsed > 0 -> {
            GroupsApplication.getString(
                if (minutesElapsed == 1L) R.string.chat_time_min
                else R.string.chat_time_mins,
                minutesElapsed.toString()
            )
        }
        else -> GroupsApplication.getString(R.string.chat_time_now)
    }
}

fun Date.isLongerThanDay() = System.currentTimeMillis() - time >= DAY_MILLIS
