/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import java.io.Serializable

data class DeepLinkModel(val roomCode: String?, var hasConfigurationChanged: Boolean = false) : Serializable {

    fun isUpdated() = roomCode != null || hasConfigurationChanged

}
