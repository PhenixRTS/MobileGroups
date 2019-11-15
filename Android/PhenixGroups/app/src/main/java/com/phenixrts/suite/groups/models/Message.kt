/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import androidx.lifecycle.MutableLiveData
import java.util.*

data class Message(
    val senderName: MutableLiveData<String> = MutableLiveData(),
    val message: String,
    val date: Date,
    val isLocal: Boolean
)