/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.phenix

import com.phenixrts.common.RequestStatus

data class PhenixException(val status: RequestStatus) : Exception()