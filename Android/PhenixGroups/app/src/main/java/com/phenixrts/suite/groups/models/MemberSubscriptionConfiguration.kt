/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import com.phenixrts.express.RoomExpress
import com.phenixrts.express.SubscribeToMemberStreamOptions

data class MemberSubscriptionConfiguration(
    val roomExpress: RoomExpress?,
    val options: SubscribeToMemberStreamOptions,
    val isVideoStream: Boolean
)
