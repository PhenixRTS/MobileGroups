/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import androidx.lifecycle.LiveData

data class Participant(
    val nickname: LiveData<String>,
    val isVideoEnabled: LiveData<Boolean>,
    val isMicrophoneEnabled: LiveData<Boolean>,
    val isLocal: Boolean = false
)