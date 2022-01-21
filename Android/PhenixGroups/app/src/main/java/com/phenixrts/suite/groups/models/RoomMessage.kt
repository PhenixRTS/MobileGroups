/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.common.extensions.elapsedTime
import com.phenixrts.suite.phenixcore.repositories.models.PhenixMessage
import java.util.*

data class RoomMessage(
    val phenixMessage: PhenixMessage,
    val isSelf: Boolean,
    var isRead: Boolean
) {
    val name = if (isSelf) GroupsApplication.getString(R.string.group_call_chat_self) else phenixMessage.memberName
    val time = Date(phenixMessage.messageDate).elapsedTime()
    val message = phenixMessage.message
}
