/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.extensions

import com.phenixrts.chat.ChatMessage
import com.phenixrts.suite.groups.BuildConfig
import java.util.*

fun MutableList<ChatMessage>.addUnique(messages: Array<ChatMessage>) {
    messages.forEach {message ->
        if (this.find { it.messageId == message.messageId } == null) {
            this.add(message)
        }
    }
    this.sortBy { it.observableTimeStamp.value }
}

fun Calendar.expirationDate(): Date {
    add(Calendar.DAY_OF_MONTH, - BuildConfig.EXPIRATION_DAYS)
    return time
}
