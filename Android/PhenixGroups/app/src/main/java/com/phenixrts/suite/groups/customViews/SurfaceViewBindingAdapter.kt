/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.customViews

import android.view.SurfaceView
import androidx.databinding.BindingAdapter
import com.phenixrts.pcast.Renderer
import com.phenixrts.pcast.android.AndroidVideoRenderSurface

object SurfaceViewBindingAdapter {
    @BindingAdapter("renderer")
    @JvmStatic
    fun videoSrc(view: SurfaceView, oldValue: Renderer?, newValue: Renderer?) {
        oldValue?.stop()
        newValue?.start(AndroidVideoRenderSurface(view.holder))
    }
}
