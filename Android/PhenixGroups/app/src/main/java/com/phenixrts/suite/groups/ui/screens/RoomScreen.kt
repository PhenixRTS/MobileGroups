/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.viewpager.widget.ViewPager
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.common.extensions.hideKeyboard
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment
import com.phenixrts.suite.groups.ui.adapters.RoomScreenPageAdapter
import kotlinx.android.synthetic.main.screen_room.*

class RoomScreen : BaseFragment(), ViewPager.OnPageChangeListener{

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?) =
        inflater.inflate(R.layout.screen_room, container, false)!!

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        service_pager?.adapter = RoomScreenPageAdapter(resources, childFragmentManager,
            viewModel.currentRoomAlias.value ?: "")
        service_pager.addOnPageChangeListener(this)

        viewModel.isControlsEnabled.value = false
        viewModel.isInRoom.value = true
    }

    override fun onBackPressed() {
        service_pager.removeOnPageChangeListener(this)
        viewModel.leaveRoom()
    }

    override fun onPageScrollStateChanged(state: Int) { /* Ignored */ }

    override fun onPageScrolled(position: Int, positionOffset: Float, positionOffsetPixels: Int) { /* Ignored */ }

    override fun onPageSelected(position: Int) {
        hideKeyboard()
    }

}
