/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.extensions

import com.phenixrts.express.PCastExpress
import com.phenixrts.pcast.UserMediaOptions
import com.phenixrts.suite.groups.models.UserMediaStatus
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

suspend fun PCastExpress.getUserMedia(options: UserMediaOptions): UserMediaStatus = suspendCoroutine { continuation ->
    getUserMedia(options) { status, stream ->
        continuation.resume(UserMediaStatus(status, stream))
    }
}
