/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common

import androidx.annotation.IdRes
import com.phenixrts.suite.groups.R

enum class SurfaceIndex(@IdRes val surfaceId: Int) {
    SURFACE_1(R.id.surface_view_1),
    SURFACE_2(R.id.surface_view_2),
    SURFACE_3(R.id.surface_view_3),
    SURFACE_4(R.id.surface_view_4),
    SURFACE_NONE(0)
}
