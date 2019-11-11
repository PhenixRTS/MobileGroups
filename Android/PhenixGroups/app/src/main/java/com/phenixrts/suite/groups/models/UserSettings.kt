/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import androidx.lifecycle.MutableLiveData

class UserSettings {
    val nickname = MutableLiveData<String>()
    val isVideoEnabled = MutableLiveData<Boolean>()
    val isMicrophoneEnabled = MutableLiveData<Boolean>()
}