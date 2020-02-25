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
import java.util.*
import kotlin.concurrent.schedule

class RoomScreen : BaseFragment() {

    private var hideControlsTask: TimerTask? = null

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?) =
        inflater.inflate(R.layout.screen_room, container, false)!!

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        service_pager?.adapter = RoomScreenPageAdapter(resources, childFragmentManager)

        mainBinding.lifecycleOwner = this
        viewModel.isControlsEnabled.value = false
        viewModel.isInRoom.value = true
        previewContainer.setOnClickListener {
            launch {
                viewModel.isControlsEnabled.value = true
                hideControlsTask?.cancel()
                hideControlsTask = Timer("hide buttons").schedule(HIDE_CONTROLS_DELAY) {
                    launch {
                        viewModel.isControlsEnabled.value = false
                    }
                }
            }
        }

        endCallButton.setOnClickListener {
            dismissFragment()
        }
    }

    override fun onBackPressed() {
        roomExpressRepository.launch {
            roomExpressRepository.leaveRoom()
        }
    }

    companion object {
        private const val HIDE_CONTROLS_DELAY = 5000L
    }
}
