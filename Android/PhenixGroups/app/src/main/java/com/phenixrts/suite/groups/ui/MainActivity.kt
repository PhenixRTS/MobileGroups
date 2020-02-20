/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui

import android.os.Bundle
import androidx.fragment.app.FragmentActivity
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.ui.screens.SplashScreen
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment

class MainActivity : FragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Show splash screen if wasn't started already
        if (savedInstanceState == null) {
            supportFragmentManager
                .beginTransaction()
                .replace(R.id.fragment, SplashScreen())
                .commit()
        }
    }

    override fun onBackPressed() {
        supportFragmentManager.run {
            fragments.forEach {
                if (it is BaseFragment) {
                    it.onBackPressed()
                }
            }
        }
        super.onBackPressed()
    }

    override fun onDestroy() {
        viewModelStore.clear()
        super.onDestroy()
    }
}
