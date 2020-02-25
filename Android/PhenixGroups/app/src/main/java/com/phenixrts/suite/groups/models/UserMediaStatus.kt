/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import com.phenixrts.common.RequestStatus
import com.phenixrts.pcast.UserMediaStream

data class UserMediaStatus(
    val status: RequestStatus = RequestStatus.OK,
    val userMediaStream: UserMediaStream? = null
)
