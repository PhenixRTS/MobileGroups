/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import androidx.lifecycle.LiveData
import com.phenixrts.suite.groups.phenix.PhenixException

interface Session {
    val errorState: LiveData<PhenixException>
    fun connect()
    fun disconnect()
}
