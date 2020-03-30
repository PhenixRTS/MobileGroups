/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import android.os.Handler
import androidx.lifecycle.MutableLiveData
import com.phenixrts.chat.ChatMessage
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.common.extensions.elapsedTime

data class RoomMessage(
    val message: ChatMessage,
    val isSelf: Boolean
) : ModelScope() {

    val observableMessageTime = MutableLiveData<String>()
    val observableSenderName = MutableLiveData<String>()
    val observableMessageBody = MutableLiveData<String>()

    init {
        refreshMessage()
    }

    private fun refreshMessage() {
        launch {
            observableMessageTime.value = message.observableTimeStamp.value.elapsedTime()
            observableSenderName.value = if (isSelf) {
                GroupsApplication.getString(R.string.group_call_chat_self)
            }
            else {
                message.observableFrom.value.observableScreenName.value
            }
            observableMessageBody.value = message.observableMessage.value

            Handler().postDelayed({
                refreshMessage()
            }, MESSAGE_TIME_UPDATE_DELAY)
        }
    }

    private companion object {
        private const val MESSAGE_TIME_UPDATE_DELAY = 1000 * 60L // 1 Minute
    }
}
