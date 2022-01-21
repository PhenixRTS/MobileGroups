/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.phenixdeeplinks.common

import com.phenixrts.suite.phenixcore.PhenixCore
import com.phenixrts.suite.phenixcore.repositories.models.PhenixConfiguration
import com.phenixrts.suite.phenixcore.repositories.models.PhenixError
import com.phenixrts.suite.phenixcore.repositories.models.PhenixEvent
import com.phenixrts.suite.phenixdeeplinks.models.PhenixDeepLinkConfiguration

private fun PhenixDeepLinkConfiguration.asPhenixConfiguration() = PhenixConfiguration(
    authToken = authToken,
    edgeToken = edgeToken,
    publishToken = publishToken,
    backend = backend,
    uri = uri,
    acts = acts,
    mimeTypes = mimeTypes,
    url = url,
    maxVideoRenderers = videoMemberCount,
    streamIDs = streams,
    channelAliases = channels,
    channelTokens = channelTokens,
    rooms = rooms,
    roomAudioToken = roomAudioToken,
    roomVideoToken = roomVideoToken,
    selectedAlias = selectedAlias,
)

/**
 * This function must be called before any other function of the [PhenixCore].
 * Use this to initialize the [PhenixCore] with an optional [PhenixDeepLinkConfiguration] object.
 * If no configuration is provided - default values will be used.
 * Once the [PhenixCore] is initialized either [onEvent] or [onError] will be notified about
 * the status of the initialization. During this period a good option is to show a "Splash Screen".
 *
 * Note that calling any other function before the initialization has been processed will
 * notify the [onError] with a error message [PhenixError.NOT_INITIALIZED].
 *
 * If the function is called twice while being initialized or after initialization,
 * then the [onError] will be notified with error message [PhenixError.ALREADY_INITIALIZING]
 * or [PhenixError.ALREADY_INITIALIZED].
 *
 * If the [PhenixCore] is successfully initialized, then the [onEvent] will be notified
 * with error [PhenixEvent.PHENIX_CORE_INITIALIZED].
 *
 * If the [PhenixCore] has failed to initialize, then the [onError] will be notified
 * with error [PhenixError.FAILED_TO_INITIALIZE].
 */
fun PhenixCore.init(config: PhenixDeepLinkConfiguration) {
    init(config.asPhenixConfiguration())
}
