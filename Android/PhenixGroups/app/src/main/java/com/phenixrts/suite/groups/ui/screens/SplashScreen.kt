/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens

import android.os.Bundle
import android.view.LayoutInflater
import android.view.ViewGroup
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment

class SplashScreen : BaseFragment() {

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?) =
        inflater.inflate(R.layout.screen_splash, container, false)!!

    override fun onStart() {
        super.onStart()
        showLandingScreen()
    }

    private fun showLandingScreen() = launch {
        viewModel.waitForPCast()
        launchFragment(LandingScreen(), false)
    }

}
