/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens

import android.content.res.Configuration
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.core.view.updateLayoutParams
import androidx.core.widget.addTextChangedListener
import com.phenixrts.common.RequestStatus
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.common.extensions.*
import com.phenixrts.suite.groups.databinding.ScreenLandingBinding
import com.phenixrts.suite.groups.ui.adapters.RoomListAdapter
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment
import com.phenixrts.suite.phenixcommon.common.launchMain
import timber.log.Timber

class LandingScreen : BaseFragment(), RoomListAdapter.OnRoomJoin {

    private lateinit var binding: ScreenLandingBinding

    private val roomAdapter = RoomListAdapter(this)
    private val isInLandscape by lazy {
        resources.configuration.orientation != Configuration.ORIENTATION_PORTRAIT
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        binding = ScreenLandingBinding.inflate(inflater)
        binding.viewModel = viewModel
        binding.lifecycleOwner = this
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.roomList.adapter = roomAdapter
        binding.newRoomButton.setOnClickListener {
            Timber.d("Create Room clicked")
            createRoom()
        }
        binding.joinRoomButton.setOnClickListener {
            launchFragment(JoinScreen())
        }
        binding.screenDisplayName.addTextChangedListener(afterTextChanged = {
            preferenceProvider.saveDisplayName(it?.toString() ?: "")
        })
        binding.landingMenuButton.setOnClickListener {
            showBottomMenu()
        }

        viewModel.displayName.value = preferenceProvider.getDisplayName()
        viewModel.isControlsEnabled.value = true
        viewModel.isInRoom.value = false
        viewModel.roomList.observe(viewLifecycleOwner, {
            Timber.d("Room list data changed: (Is portrait: $isInLandscape), $it")
            updateRoomListHeight(it.size)
            roomAdapter.data = it
        })
        if (viewModel.isVideoEnabled.isTrue()) {
            getSurfaceView().visibility = View.VISIBLE
        } else {
            getSurfaceView().visibility = View.GONE
        }
        if (viewModel.isMicrophoneEnabled.isTrue()) {
            getMicIcon().visibility = View.GONE
        } else {
            getMicIcon().visibility = View.VISIBLE
        }

        if (resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            hideTopMenu()
        }
        restartVideoPreview(viewModel)
    }

    override fun onRoomJoinClicked(roomId: String) {
        Timber.d("Join clicked for: $roomId")
        joinRoomById(roomId)
    }

    private fun updateRoomListHeight(itemCount: Int) {
        if (isInLandscape) return
        val adapterHeight = resources.getDimension(R.dimen.room_item_height) * if (itemCount <= 3) itemCount else 3
        binding.roomList.updateLayoutParams {
            height = adapterHeight.toInt()
        }
    }

    /**
     * Create a new meeting room
     */
    private fun createRoom() = launchMain {
        if (!hasCameraPermission()) {
            viewModel.onPermissionRequested.call()
            return@launchMain
        }
        showLoadingScreen()
        val response = viewModel.createRoom()
        if (response.status == RequestStatus.OK) {
            joinRoomById(response.message)
        } else {
            showToast(getString(R.string.err_create_room_failed))
            hideLoadingScreen()
        }
    }

    private fun joinRoomById(roomId: String) = launchMain {
        if (!hasCameraPermission()) {
            viewModel.onPermissionRequested.call()
            return@launchMain
        }
        showLoadingScreen()
        viewModel.joinRoomById(roomId, preferenceProvider.getDisplayName())
    }

}
