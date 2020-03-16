/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.extensions

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

fun Member.getRoomMember(members: List<RoomMember>): RoomMember {
    var roomMember: RoomMember? = null
    members.takeIf { it.isNotEmpty() }?.let { memberList ->
        memberList.forEach {
            if (it.member.sessionId == this.sessionId) {
                roomMember = it
            }
        }
    }
    return roomMember ?: RoomMember(this)
}

fun List<RoomMember>.isListUpdated(oldMembers: List<RoomMember>?): Boolean {
    var updated = size != oldMembers?.size
    forEach { member ->
        val oldMember = oldMembers?.firstOrNull { it.member.sessionId == member.member.sessionId }
        if (oldMember == null || oldMember.surface != member.surface) {
            updated = true
        }
    }
    return updated
}

fun Calendar.expirationDate(): Date {
    add(Calendar.DAY_OF_MONTH, - BuildConfig.EXPIRATION_DAYS)
    return time
}
