/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.extensions

import com.phenixrts.express.PCastExpress
import com.phenixrts.pcast.UserMediaOptions
import com.phenixrts.suite.groups.models.UserMediaStatus
import timber.log.Timber
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

suspend fun PCastExpress.getUserMedia(options: UserMediaOptions): UserMediaStatus = suspendCoroutine { continuation ->
    getUserMedia(options) { status, stream ->
        Timber.d("Collecting media stream from pCast: $status")
        continuation.resume(UserMediaStatus(status, stream))
    }
}
