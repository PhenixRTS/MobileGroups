/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens

import android.Manifest
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.lifecycle.Observer
import com.phenixrts.common.RequestStatus
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.common.EasyPermissionFragment
import com.phenixrts.suite.groups.common.extensions.showToast
import com.phenixrts.suite.groups.databinding.ScreenLandingBinding
import com.phenixrts.suite.groups.ui.adapters.RoomListAdapter
import timber.log.Timber

class LandingScreen : EasyPermissionFragment(), RoomListAdapter.OnRoomJoin {

    private lateinit var binding: ScreenLandingBinding

    private val roomAdapter = RoomListAdapter(this)

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        binding = ScreenLandingBinding.inflate(inflater)
        binding.model = viewModel
        binding.lifecycleOwner = this
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        binding.roomList.setHasFixedSize(true)
        binding.cameraButton.setOnCheckedChangeListener(::setCameraPreviewEnabled)
        binding.microphoneButton.setOnCheckedChangeListener(::setMicrophoneEnabled)

        binding.newRoomButton.setOnClickListener {
            createRoom()
        }
        binding.joinRoomButton.setOnClickListener {
            launchFragment(JoinScreen())
        }

        viewModel.roomList.observe(this, Observer {
            Timber.d("Room list data changed $it")
            roomAdapter.data = it
            if (binding.roomList.adapter == null) {
                binding.roomList.adapter = roomAdapter
            }
        })
    }

    private fun setCameraPreviewEnabled(enabled: Boolean) {
        if (enabled) {
            askForPermission(Manifest.permission.CAMERA) { granted ->
                // TODO (YM): add camera preview switch logic
                if (!granted) {
                    binding.cameraButton.isChecked = false
                }
            }
        }
    }

    private fun setMicrophoneEnabled(enabled: Boolean) {
        if (enabled) {
            askForPermission(Manifest.permission.RECORD_AUDIO) { granted ->
                // TODO (YM): show settings dialog if denied
                if (!granted) {
                    binding.microphoneButton.isChecked = false
                }
            }
        }
    }

    /**
     * Create a new meeting room
     */
    private fun createRoom() {
        showLoadingScreen()
        roomExpressRepository.launch {
            val response = roomExpressRepository.createRoom()
            if (response.status == RequestStatus.OK) {
                joinRoomById(response.message)
            } else {
                showToast(getString(R.string.err_create_room_failed))
                hideLoadingScreen()
            }
        }
    }

    override fun onRoomJoinClicked(roomId: String) {
        Timber.d("Join clicked for: $roomId")
        joinRoomById(roomId)
    }
}
