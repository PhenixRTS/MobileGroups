/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import androidx.lifecycle.LiveData
import com.phenixrts.pcast.Renderer

// TODO: This will be removed in future - when work on Participants is started
abstract class Participant(
    val screenName: String,
    val isVideoEnabled: LiveData<Boolean>,
    val isMicrophoneEnabled: LiveData<Boolean>,
    val isLocal: Boolean
) {
    abstract val renderer: LiveData<Renderer>
}
