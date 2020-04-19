/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.extensions

import android.view.View
import androidx.lifecycle.MutableLiveData
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.phenixrts.chat.ChatMessage
import com.phenixrts.room.Member
import com.phenixrts.suite.groups.BuildConfig
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.databinding.RowMemberItemBinding
import com.phenixrts.suite.groups.models.RoomMember
import com.phenixrts.suite.groups.models.RoomMessage
import java.util.*

private const val MINUTE_MILLIS = 1000 * 60L
private const val HOUR_MILLIS = MINUTE_MILLIS * 60L
private const val DAY_MILLIS = HOUR_MILLIS * 24L
private const val MONTH_MILLIS = DAY_MILLIS * 30L
private const val YEAR_MILLIS = MONTH_MILLIS * 12L

fun MutableList<RoomMessage>.addUnique(messages: Array<ChatMessage>, selfName: String, isViewingChat: Boolean) {
    messages.forEach {message ->
        if (this.find { it.message.messageId == message.messageId } == null) {
            val isSelf = selfName == message.observableFrom.value.observableScreenName.value
            this.add(RoomMessage(message, isSelf, isViewingChat))
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

fun BottomSheetBehavior<View>.isOpened() = state == BottomSheetBehavior.STATE_EXPANDED

fun BottomSheetBehavior<View>.open() {
    if (state != BottomSheetBehavior.STATE_EXPANDED) {
        state = BottomSheetBehavior.STATE_EXPANDED
    }
}

fun BottomSheetBehavior<View>.hide() {
    if (state != BottomSheetBehavior.STATE_HIDDEN) {
        state = BottomSheetBehavior.STATE_HIDDEN
    }
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
    val currentCalendar = Calendar.getInstance()
    val calendar = Calendar.getInstance()
    calendar.time = this

    val minutes = calendar.time.time / MINUTE_MILLIS
    val hours = calendar.time.time / HOUR_MILLIS
    val days = calendar.time.time / DAY_MILLIS
    val months = calendar.time.time / MONTH_MILLIS
    val years = calendar.time.time / YEAR_MILLIS
    val currentMinutes = currentCalendar.time.time / MINUTE_MILLIS
    val currentHours = currentCalendar.time.time / HOUR_MILLIS
    val currentDays = currentCalendar.time.time / DAY_MILLIS
    val currentMonths = currentCalendar.time.time / MONTH_MILLIS
    val currentYears = currentCalendar.time.time / YEAR_MILLIS

    val minutesElapsed = currentMinutes - minutes
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
