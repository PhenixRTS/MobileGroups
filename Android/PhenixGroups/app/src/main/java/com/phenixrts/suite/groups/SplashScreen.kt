/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import kotlin.concurrent.thread


class SplashScreen : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.splash_screen, container, false)
    }

    override fun onStart() {
        super.onStart()
        thread {
            // TODO (YM): init PhenixSDK
            fragmentManager?.run {
                beginTransaction()
                    .replace(R.id.fragment, CallSettingsScreen())
                    .commit()
            }
        }
    }
}