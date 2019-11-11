/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.phenix

import android.content.Context
import android.util.Log
import com.phenixrts.common.RequestStatus
import com.phenixrts.environment.android.AndroidContext
import com.phenixrts.express.PCastExpressFactory
import com.phenixrts.express.RoomExpress
import com.phenixrts.express.RoomExpressFactory

object PhenixComponent {
    private val TAG = PhenixComponent::class.java.simpleName

    lateinit var roomExpress: RoomExpress
        private set

    fun initialize(
        context: Context,
        backend: PhenixBackend = PhenixBackend.PRODUCTION
    ) {
        Log.d(TAG, "Initialising RoomExpress")
        AndroidContext.setContext(context)

        val pcastExpressOptions = PCastExpressFactory.createPCastExpressOptionsBuilder()
            .withBackendUri(backend.backendUrl)
            .withPCastUri(backend.pcastUrl)
            .withUnrecoverableErrorCallback { status: RequestStatus, description: String ->
                // TODO (YM): re-create PCastExpress?!
                Log.e(
                    TAG, "Unrecoverable error in PhenixSDK. " +
                            "Error status: [$status]. " +
                            "Description: [$description]"
                )
            }
            .buildPCastExpressOptions()

        val roomExpressOptions = RoomExpressFactory.createRoomExpressOptionsBuilder()
            .withPCastExpressOptions(pcastExpressOptions)
            .buildRoomExpressOptions()

        roomExpress = RoomExpressFactory.createRoomExpress(roomExpressOptions)
        Log.d(TAG, "RoomExpress initialised")
    }

}