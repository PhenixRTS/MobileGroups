/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.phenix

import android.os.Handler
import android.os.Looper
import androidx.lifecycle.MutableLiveData
import com.phenixrts.common.Disposable
import com.phenixrts.common.Observable

private val mainThreadHandler = Handler(Looper.getMainLooper())

// FIXME(YM): Fix Phenix SDK generic in Observable API
fun <T> Observable<T>.fixedSubscribe(callback: Observable.OnChangedHandler<T>): Disposable =
    subscribe(callback)

/**
 * Convert Phenix observable to Android LiveData
 */
fun <T> Observable<T>.toMutableLiveData(): MutableLiveData<T> {
    return MutableLiveData<T>().apply {
        fixedSubscribe(Observable.OnChangedHandler {
            mainThreadHandler.post {
                if (value != it) {
                    value = it
                }
            }
        })

        mainThreadHandler.post {
            observeForever { newLiveDataValue ->
                if (this@toMutableLiveData.value != newLiveDataValue) {
                    this@toMutableLiveData.value = newLiveDataValue
                }
            }
        }
    }
}