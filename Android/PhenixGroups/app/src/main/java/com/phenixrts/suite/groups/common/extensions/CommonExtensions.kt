/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.extensions

import com.phenixrts.chat.ChatMessage
import com.phenixrts.suite.groups.common.getFormattedDate
import com.phenixrts.suite.groups.cache.entities.ChatMessageItem

fun Array<ChatMessage>.asChatMessageItems(roomId: String): List<ChatMessageItem> {
    val messages = mutableListOf<ChatMessageItem>()
    forEach {
        messages.add(it.asChatMessageItem(roomId))
    }
    return messages
}

fun ChatMessage.asChatMessageItem(roomId: String): ChatMessageItem {
    return ChatMessageItem(
        messageId,
        observableFrom.value.observableScreenName.value,
        observableMessage.value,
        getFormattedDate(observableTimeStamp.value),
        roomId
    )
}
