/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.extensions

import com.phenixrts.express.PCastExpress
import com.phenixrts.pcast.UserMediaOptions
import com.phenixrts.suite.groups.models.UserMediaStatus
import kotlinx.coroutines.*
import timber.log.Timber
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

private val mainScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
private val ioScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

suspend fun PCastExpress.getUserMedia(options: UserMediaOptions): UserMediaStatus = suspendCoroutine { continuation ->
    getUserMedia(options) { status, stream ->
        Timber.d("Collecting media stream from pCast: $status")
        continuation.resume(UserMediaStatus(status, stream))
    }
}

fun launchMain(block: suspend CoroutineScope.() -> Unit) = mainScope.launch(
    context = CoroutineExceptionHandler { _, e ->
        Timber.e("Coroutine failed: ${e.localizedMessage}")
        e.printStackTrace()
    },
    block = block
)

fun launchIO(block: suspend CoroutineScope.() -> Unit) = ioScope.launch(
    context = CoroutineExceptionHandler { _, e ->
        Timber.w("Coroutine failed: ${e.localizedMessage}")
        e.printStackTrace()
    },
    block = block
)
