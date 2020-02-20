/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.cache.entities

import android.os.Build
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "chat_item")
data class ChatMessageItem(
    @PrimaryKey
    val messageId: String,
    val userName: String,
    val message: String,
    val date: String,
    // TODO: If we wan't to store chat messages - we should know for which room the message is meant
    val roomId: String = "",
    // TODO: There are multiple ways to set this:
    //  - use local cache and when an outgoing message is sent - update this to true
    //  - SDK provides some isSelf variable for ChatMessage
    //  - use some kind of user ID to map chat messages to user
    var isLocal: Boolean = userName == Build.MODEL
)
