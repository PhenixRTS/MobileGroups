/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import androidx.lifecycle.LiveData
import com.phenixrts.pcast.Renderer

abstract class Participant(
    val nickname: LiveData<String>,
    val isVideoEnabled: LiveData<Boolean>,
    val isMicrophoneEnabled: LiveData<Boolean>,
    val isLocal: Boolean
) {
    abstract val renderer: LiveData<Renderer>
}