/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens

import android.os.Bundle
import android.view.LayoutInflater
import android.view.ViewGroup
import com.phenixrts.suite.groups.databinding.ScreenLoadingBinding
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment

class LoadingScreen : BaseFragment() {

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?) =
        ScreenLoadingBinding.inflate(inflater, container, false).root

}
