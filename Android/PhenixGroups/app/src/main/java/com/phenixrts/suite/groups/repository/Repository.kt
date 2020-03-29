/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.repository

import kotlinx.coroutines.*
import timber.log.Timber

const val DEBOUNCE_DELAY = 1000L

abstract class Repository {

    private var currentDelay = 0L

    private val repositoryScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    protected fun launch(block: suspend CoroutineScope.() -> Unit) = repositoryScope.launch(
        context = CoroutineExceptionHandler { _, e ->
            Timber.w("Coroutine failed: ${e.localizedMessage}")
            e.printStackTrace()
        },
        block = block
    )

    protected suspend fun debounce() {
        currentDelay += currentDelay + DEBOUNCE_DELAY
        Timber.d("Debouncing coroutine by $currentDelay")
        delay(currentDelay)
        currentDelay = 0L
    }

}
