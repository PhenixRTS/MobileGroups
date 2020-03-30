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
import com.phenixrts.suite.groups.common.getFormattedDate
import com.phenixrts.suite.groups.databinding.RowMemberItemBinding
import com.phenixrts.suite.groups.models.RoomMember
import com.phenixrts.suite.groups.models.RoomMessage
import java.util.*

private const val MAX_MESSAGE_INTERVAL = 30 // Minutes

fun MutableList<RoomMessage>.addUnique(messages: Array<ChatMessage>, selfName: String) {
    messages.forEach {message ->
        if (this.find { it.message.messageId == message.messageId } == null) {
            this.add(RoomMessage(message, selfName == message.observableFrom.value.observableScreenName.value))
        }
    }
    this.sortBy { it.message.observableTimeStamp.value }
}

fun MutableLiveData<Boolean>.isTrue(default: Boolean = false) = value ?: default

fun MutableLiveData<Boolean>.isFalse(default: Boolean = true) = value?.not() ?: default

fun MutableLiveData<Unit>.call() {
    value = Unit
}

fun RowMemberItemBinding.refresh() {
    this.member = this.member
}

fun Member.getRoomMember(members: List<RoomMember>): RoomMember {
    val roomMember = members.takeIf { it.isNotEmpty() }
        ?.firstOrNull { it.member.sessionId == this.sessionId }
    return roomMember ?: RoomMember(this)
}

fun Calendar.expirationDate(): Date {
    add(Calendar.DAY_OF_MONTH, - BuildConfig.EXPIRATION_DAYS)
    return time
}

fun Date.elapsedTime(): String {
    val currentCalendar = Calendar.getInstance()
    val calendar = Calendar.getInstance()
    calendar.time = this

    val minute = calendar.time.time / (1000 * 60)
    val currentMinute = currentCalendar.time.time / (1000 * 60)
    val interval = currentMinute - minute

    return if (interval < MAX_MESSAGE_INTERVAL) GroupsApplication.getString(
        // TODO: Update this to reflect message time greater than 24h
        when (interval) {
            in 0 until 1 -> R.string.chat_time_now
            1L -> R.string.chat_time_min
            in 2 until MAX_MESSAGE_INTERVAL -> R.string.chat_time_mins
            else -> R.string.chat_time_now
        }, interval.toString()) else getFormattedDate(this)
}
