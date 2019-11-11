/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData

data class Participant(
    val nickname: LiveData<String>,
    val isVideoEnabled: MutableLiveData<Boolean>,
    val isMicrophoneEnabled: MutableLiveData<Boolean>,
    val isLocal: Boolean = false
)