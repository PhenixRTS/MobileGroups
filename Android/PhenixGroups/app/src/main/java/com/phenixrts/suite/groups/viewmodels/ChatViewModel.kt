/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.viewmodels

import androidx.databinding.ObservableArrayList
import androidx.lifecycle.ViewModel
import com.phenixrts.suite.groups.models.Message
import com.phenixrts.suite.groups.models.RoomModel

class ChatViewModel : ViewModel(), RoomModel.OnChatEventsListener {
    val chatHistory = ObservableArrayList<Message>()
    private lateinit var roomModel: RoomModel

    fun init(roomModel: RoomModel) {
        this.roomModel = roomModel
        roomModel.addOnChatEventsListener(this)
    }

    override fun onNewChatMessage(message: Message) {
        chatHistory.add(message)
    }

    fun sendChatMessage(message: String?, callback: OnSendMessageCallback) {
        message?.run {
            roomModel.sendChatMessage(
                message,
                { callback.onSuccess() },
                { callback.onError(it) })
        }
    }

    interface OnSendMessageCallback {
        fun onSuccess()
        fun onError(error: Exception)
    }
}