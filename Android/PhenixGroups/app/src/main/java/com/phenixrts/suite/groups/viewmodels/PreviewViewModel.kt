/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.viewmodels

import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import com.phenixrts.suite.groups.models.Participant

class PreviewViewModel : ViewModel() {
    val activeParticipant = MutableLiveData<Participant>()
}