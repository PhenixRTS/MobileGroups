/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.viewmodels

import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import com.phenixrts.suite.groups.utils.StubData

class CallSettingsViewModel : ViewModel() {
    val nickname = MutableLiveData<String>(StubData.USER_NAME) // TODO(YM): remove stub
    val isVideoEnabled = MutableLiveData<Boolean>()
    val isMicrophoneEnabled = MutableLiveData<Boolean>()

    val roomName = MutableLiveData<String>(StubData.APP_ROOM_ALIAS)
}