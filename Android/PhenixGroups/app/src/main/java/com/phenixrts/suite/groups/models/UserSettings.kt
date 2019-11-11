/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel

class UserSettings : ViewModel() {
    val nickname = MutableLiveData<String>("Stub Name") // TODO(YM): remove stub
    val isVideoEnabled = MutableLiveData<Boolean>()
    val isMicrophoneEnabled = MutableLiveData<Boolean>()
}