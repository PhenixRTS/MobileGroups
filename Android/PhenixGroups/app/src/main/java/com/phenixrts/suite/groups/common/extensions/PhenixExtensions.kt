/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.extensions

import android.os.Handler
import android.os.Looper
import androidx.lifecycle.MutableLiveData
import com.phenixrts.common.Disposable
import com.phenixrts.common.Observable

private val mainThreadHandler = Handler(Looper.getMainLooper())

/**
 * TODO: This is not needed because we use coroutines now,
 *  this will be removed once work on participants is started
 * Convert Phenix observable to Android LiveData
 */
fun <T> Observable<T>.toMutableLiveData(): MutableLiveData<T> {
    return MutableLiveData<T>().apply {
        subscribe {
            if (value != it) {
                postValue(it)
            }
        }

        mainThreadHandler.post {
            observeForever { newLiveDataValue ->
                if (this@toMutableLiveData.value != newLiveDataValue) {
                    this@toMutableLiveData.value = newLiveDataValue
                }
            }
        }
    }
}
