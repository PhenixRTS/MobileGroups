/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.utils

@Deprecated("For testing purpose only")
object StubData {
    val USER_NAME = android.os.Build.MODEL
    val APP_ROOM_ALIAS = "yevgen4"

    enum class PhenixServer(val backendUrl: String, val pcastUrl: String = "") {
        PRODUCTION("https://demo.phenixrts.com/pcast"),
        STAGING(
            "https://demo-stg.phenixrts.com/pcast",
            "https://pcast-stg.phenixrts.com/"
        )
    }
}