/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.phenix

enum class PhenixBackend(val backendUrl: String, val pcastUrl: String = "") {
    PRODUCTION("https://demo.phenixrts.com/pcast"),
    STAGING(
        "https://demo-stg.phenixrts.com/pcast",
        "https://pcast-stg.phenixrts.com/"
    )
}