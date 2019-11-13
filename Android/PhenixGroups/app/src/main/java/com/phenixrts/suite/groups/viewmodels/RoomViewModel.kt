/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.viewmodels

import android.util.Log
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import com.phenixrts.suite.groups.models.RoomModel

class RoomViewModel : ViewModel(), RoomModel.OnConnectionEventsListener {
    private val TAG = RoomViewModel::class.java.simpleName

    val errorState = MutableLiveData<Exception>()

    private lateinit var roomModel: RoomModel

    fun initialize(roomModel: RoomModel) {
        this.roomModel = roomModel
        roomModel.addOnConnectionEventsListener(this)
    }

    override fun onSubscribed() {
        errorState.value = null
    }

    override fun onError(error: Exception) {
        errorState.value = error
        Log.e(TAG, "Connection error", error)
    }


}