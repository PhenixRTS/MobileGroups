/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.phenixcore.repositories.models

data class PhenixConfiguration(
    val authToken: String? = null,
    val edgeToken: String? = null,
    val publishToken: String? = null,
    val backend: String? = null,
    val uri: String? = null,
    val acts: List<String> = listOf(),
    val mimeTypes: List<String> = listOf(),
    val url: String? = null,
    val maxVideoRenderers: Int? = null,
    val streamIDs: List<String> = listOf(),
    val channelAliases: List<String> = listOf(),
    val channelTokens: List<String> = listOf(),
    val rooms: List<String> = listOf(),
    val roomAudioToken: String? = null,
    val roomVideoToken: String? = null,
    val selectedAlias: String? = null
)
