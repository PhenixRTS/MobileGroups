/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment
import com.phenixrts.suite.groups.ui.adapters.RoomScreenPageAdapter
import kotlinx.android.synthetic.main.screen_room.*

class RoomScreen : BaseFragment() {

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?) =
        inflater.inflate(R.layout.screen_room, container, false)!!

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        service_pager?.adapter = RoomScreenPageAdapter(resources, childFragmentManager,
            viewModel.currentRoomAlias.value ?: "")

        viewModel.isControlsEnabled.value = false
        viewModel.isInRoom.value = true
        restartVideoPreview()
    }

    override fun onBackPressed() {
        viewModel.stopMediaRenderer()
        viewModel.leaveRoom()
    }

}
