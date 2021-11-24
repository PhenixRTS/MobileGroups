/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens

import android.content.res.Configuration
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.core.view.updateLayoutParams
import androidx.core.widget.doAfterTextChanged
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.common.extensions.*
import com.phenixrts.suite.groups.common.getRoomCode
import com.phenixrts.suite.groups.databinding.ScreenLandingBinding
import com.phenixrts.suite.groups.ui.adapters.RoomListAdapter
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment
import com.phenixrts.suite.phenixcore.common.launchUI
import timber.log.Timber

class LandingScreen : BaseFragment() {

    private lateinit var binding: ScreenLandingBinding

    private val roomAdapter by lazy {
        RoomListAdapter { roomAlias ->
            Timber.d("Join clicked for: $roomAlias")
            joinRoom(roomAlias)
        }
    }
    private val isInLandscape by lazy {
        resources.configuration.orientation != Configuration.ORIENTATION_PORTRAIT
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        binding = ScreenLandingBinding.inflate(inflater, container, false)
        binding.viewModel = viewModel
        binding.lifecycleOwner = this
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.roomList.adapter = roomAdapter
        binding.newRoomButton.setOnClickListener {
            Timber.d("Create Room clicked")
            joinRoom()
        }
        binding.joinRoomButton.setOnClickListener {
            launchFragment(JoinScreen())
        }
        binding.screenDisplayName.doAfterTextChanged {
            viewModel.displayName = it?.toString() ?: ""
        }
        binding.landingMenuButton.setOnClickListener {
            showBottomMenu()
        }

        launchUI {
            viewModel.roomList.collect { rooms ->
                Timber.d("Room list data changed: (Is portrait: $isInLandscape), $rooms")
                updateRoomListHeight(rooms.size)
                roomAdapter.data = rooms
            }
        }

        if (resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            hideTopMenu()
        }
    }

    private fun updateRoomListHeight(itemCount: Int) {
        if (isInLandscape) return
        val adapterHeight = resources.getDimension(R.dimen.room_item_height) * if (itemCount <= 3) itemCount else 3
        binding.roomList.updateLayoutParams {
            height = adapterHeight.toInt()
        }
    }

    private fun joinRoom(roomAlias: String = getRoomCode()) {
        launchUI {
            if (!hasCameraPermission()) {
                askForPermissions { joinRoom(roomAlias) }
                return@launchUI
            }
            viewModel.joinRoom(roomAlias = roomAlias)
        }
    }
}
