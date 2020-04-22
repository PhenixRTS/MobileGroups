/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import java.io.Serializable

data class DeepLinkModel(val roomCode: String?, val uri: String?, val backend: String?) : Serializable
