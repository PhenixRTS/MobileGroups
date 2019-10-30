/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups

import android.os.Bundle
import androidx.fragment.app.FragmentActivity

class MainActivity : FragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.main_activity)

        // set initial screen
        supportFragmentManager.beginTransaction().replace(R.id.fragment, SplashScreen()).commit()
    }
}