/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.lifecycle.Observer
import com.phenixrts.common.RequestStatus
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.common.SurfaceIndex
import com.phenixrts.suite.groups.common.extensions.showGivenSurfaceView
import com.phenixrts.suite.groups.common.extensions.showToast
import com.phenixrts.suite.groups.databinding.ScreenLandingBinding
import com.phenixrts.suite.groups.ui.adapters.RoomListAdapter
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment
import timber.log.Timber

class LandingScreen : BaseFragment(), RoomListAdapter.OnRoomJoin {

    private lateinit var binding: ScreenLandingBinding

    private val roomAdapter = RoomListAdapter(this)

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        binding = ScreenLandingBinding.inflate(inflater)
        binding.viewModel = viewModel
        binding.lifecycleOwner = this
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.roomList.setHasFixedSize(true)
        binding.roomList.adapter = roomAdapter
        binding.newRoomButton.setOnClickListener {
            createRoom()
        }
        binding.joinRoomButton.setOnClickListener {
            launchFragment(JoinScreen())
        }

        viewModel.isControlsEnabled.value = true
        viewModel.isInRoom.value = false
        viewModel.roomList.observe(viewLifecycleOwner, Observer {
            Timber.d("Room list data changed $it")
            roomAdapter.data = it
        })
        showGivenSurfaceView(SurfaceIndex.SURFACE_1)
        restartVideoPreview()
    }

    override fun onRoomJoinClicked(roomId: String) {
        Timber.d("Join clicked for: $roomId")
        joinRoomById(roomId)
    }

    /**
     * Create a new meeting room
     */
    private fun createRoom() = launch {
        showLoadingScreen()
        val response = viewModel.createRoom()
        if (response.status == RequestStatus.OK) {
            joinRoomById(response.message)
        } else {
            showToast(getString(R.string.err_create_room_failed))
            hideLoadingScreen()
        }
    }

    private fun joinRoomById(roomId: String) = launch {
        showLoadingScreen()
        val joinedRoomStatus = viewModel.joinRoomById(roomId, preferenceProvider.getDisplayName())
        Timber.d("Room joined with status: $joinedRoomStatus")
        hideLoadingScreen()
        if (joinedRoomStatus.status == RequestStatus.OK) {
            launchFragment(RoomScreen())
        } else {
            showToast(getString(R.string.err_join_room_failed))
        }
    }

}
