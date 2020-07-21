/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import com.phenixrts.common.RequestStatus
import com.phenixrts.express.ExpressPublisher
import com.phenixrts.room.RoomService

data class JoinedRoomStatus(
    val status: RequestStatus,
    val roomService: RoomService? = null,
    val publisher: ExpressPublisher? = null
) {

    fun isConnected() = status == RequestStatus.OK && roomService != null && publisher != null
}
