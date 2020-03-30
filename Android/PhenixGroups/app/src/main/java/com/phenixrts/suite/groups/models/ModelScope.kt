/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import kotlinx.coroutines.*
import timber.log.Timber

abstract class ModelScope {

    private val modelScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    fun launch(block: suspend CoroutineScope.() -> Unit) = modelScope.launch(
        context = CoroutineExceptionHandler { _, e ->
            Timber.w("Coroutine failed: ${e.localizedMessage}")
            e.printStackTrace()
        },
        block = block
    )
}
