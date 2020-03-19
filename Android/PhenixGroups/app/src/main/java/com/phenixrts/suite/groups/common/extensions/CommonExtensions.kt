/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.extensions

import androidx.lifecycle.MutableLiveData
import com.phenixrts.chat.ChatMessage
import com.phenixrts.room.Member
import com.phenixrts.suite.groups.BuildConfig
import com.phenixrts.suite.groups.models.RoomMember
import java.util.*

fun MutableList<ChatMessage>.addUnique(messages: Array<ChatMessage>) {
    messages.forEach {message ->
        if (this.find { it.messageId == message.messageId } == null) {
            this.add(message)
        }
    }
    this.sortBy { it.observableTimeStamp.value }
}

fun MutableLiveData<Boolean>.isTrue(default: Boolean = false) = value ?: default

fun MutableLiveData<Boolean>.isFalse(default: Boolean = true) = value?.not() ?: default

fun MutableLiveData<Boolean>.call(restartRenderer: Boolean = true) {
    value = restartRenderer
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
