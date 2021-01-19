/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

import com.phenixrts.suite.groups.BuildConfig
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

const val QUERY_URI = "uri"
const val QUERY_BACKEND = "backend"

@Serializable
data class RoomExpressConfiguration(
    val uri: String = BuildConfig.PCAST_URL,
    val backend: String = BuildConfig.BACKEND_URL
)

fun String.fromJson(): RoomExpressConfiguration? = try {
    Json{ ignoreUnknownKeys = true }.decodeFromString(this)
} catch (e: Exception) {
    null
}

fun RoomExpressConfiguration.toJson(): String = Json.encodeToString(this)
