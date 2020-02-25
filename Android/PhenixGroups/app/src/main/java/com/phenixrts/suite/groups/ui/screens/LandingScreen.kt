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
        binding.viewModel = viewModel
        binding.lifecycleOwner = this
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        cameraButton.setOnCheckedChangeListener(::setCameraPreviewEnabled)
        microphoneButton.setOnCheckedChangeListener(::setMicrophoneEnabled)

        binding.roomList.setHasFixedSize(true)
        binding.roomList.adapter = roomAdapter
        binding.newRoomButton.setOnClickListener {
            createRoom()
        }
        binding.joinRoomButton.setOnClickListener {
            launchFragment(JoinScreen())
        }

        mainBinding.lifecycleOwner = this
        viewModel.isControlsEnabled.value = true
        viewModel.isInRoom.value = false
        viewModel.roomList.observe(this, Observer {
            Timber.d("Room list data changed $it")
            roomAdapter.data = it
        })
        viewModel.onRoomCreated.observe(this, Observer { response ->
            if (response.status == RequestStatus.OK) {
                joinRoomById(response.message)
            } else {
                showToast(getString(R.string.err_create_room_failed))
                hideLoadingScreen()
            }
        })

        setCameraPreviewEnabled(true)
        setMicrophoneEnabled(true)
    }

    override fun onDestroy() {
        super.onDestroy()
        roomExpressRepository.launch {
            roomExpressRepository.stopMediaStream()
        }
    }

    override fun onRoomJoinClicked(roomId: String) {
        Timber.d("Join clicked for: $roomId")
        joinRoomById(roomId)
    }

    private fun setCameraPreviewEnabled(enabled: Boolean) {
        askForPermission(Manifest.permission.CAMERA) { granted ->
            if (!granted) {
                cameraButton.isChecked = false
                viewModel.isVideoEnabled.value = false
            } else {
                previewUserVideo(enabled)
            }
        }
    }

    private fun setMicrophoneEnabled(enabled: Boolean) {
        if (enabled) {
            askForPermission(Manifest.permission.RECORD_AUDIO) { granted ->
                if (!granted) {
                    microphoneButton.isChecked = false
                    viewModel.isMicrophoneEnabled.value = false
                } else {
                    viewModel.isMicrophoneEnabled.value = enabled
                }
            }
        }
    }

    /**
     * Create a new meeting room
     */
    private fun createRoom() {
        showLoadingScreen()
        viewModel.createRoom()
    }

    private fun previewUserVideo(start: Boolean) {
        Timber.d("Preview user media: $start")
        viewModel.isVideoEnabled.value = start
        if (start) {
            roomExpressRepository.launch {
                val response = roomExpressRepository.startUserVideoPreview(surfaceView.holder)
                launch {
                    if (response.status == RequestStatus.OK) {
                        surfaceView.visibility = View.VISIBLE
                    } else {
                        showToast(response.message)
                    }
                }
            }
        } else {
            surfaceView.visibility = View.GONE
        }
    }
}
