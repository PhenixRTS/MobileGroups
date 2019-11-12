/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import androidx.lifecycle.LiveData
import java.util.*

data class ChatMessage(val senderName: LiveData<String>, val message: String, val date: Date)