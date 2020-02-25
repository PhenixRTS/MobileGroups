/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.extensions

import com.phenixrts.chat.ChatMessage

fun MutableList<ChatMessage>.addUnique(messages: Array<ChatMessage>) {
    messages.forEach {message ->
        if (this.find { it.messageId == message.messageId } == null) {
            this.add(message)
        }
    }
}
