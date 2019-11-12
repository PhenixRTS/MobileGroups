/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.viewmodels

import androidx.databinding.ObservableArrayList
import androidx.lifecycle.ViewModel
import com.phenixrts.suite.groups.models.ChatMessage

class ChatViewModel : ViewModel() {
    val roomChat = ObservableArrayList<ChatMessage>()

    fun sendChatMessage(message: String) {
        TODO("Send message")
    }
}