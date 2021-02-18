/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import com.phenixrts.common.RequestStatus

data class RoomStatus(
    val status: RequestStatus,
    val message: String = ""
)
