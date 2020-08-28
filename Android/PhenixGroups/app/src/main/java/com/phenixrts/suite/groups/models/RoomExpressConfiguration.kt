/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import com.phenixrts.suite.groups.BuildConfig
import java.io.Serializable

const val QUERY_URI = "uri"
const val QUERY_BACKEND = "backend"

data class RoomExpressConfiguration(
    val uri: String = BuildConfig.PCAST_URL,
    val backend: String = BuildConfig.BACKEND_URL
) : Serializable
