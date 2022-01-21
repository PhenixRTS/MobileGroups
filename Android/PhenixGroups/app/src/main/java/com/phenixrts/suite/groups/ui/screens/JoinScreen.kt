/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens

import android.os.Bundle
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.transition.Slide
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.common.extensions.DEFAULT_ANIMATION_DURATION
import com.phenixrts.suite.groups.common.extensions.dismissFragment
import com.phenixrts.suite.groups.common.extensions.showToast
import com.phenixrts.suite.groups.databinding.FragmentJoinBinding
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment
import timber.log.Timber

class JoinScreen : BaseFragment() {

    private lateinit var binding: FragmentJoinBinding

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        binding = FragmentJoinBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        binding.joinRoomDismissButton.setOnClickListener {
            dismissFragment()
        }
        binding.joinRoomButton.setOnClickListener {
            binding.joinRoomCodeInput.text.toString().takeIf { it.isNotBlank() }?.let { alias ->
                Timber.d("Join Room clicked: $alias")
                viewModel.joinRoom(roomAlias = alias)
            } ?: showToast(getString(R.string.err_enter_valid_room_code))
        }
    }

    override fun getEnterTransition() = Slide(Gravity.BOTTOM).apply {
        duration = DEFAULT_ANIMATION_DURATION
    }

    override fun getReturnTransition(): Any = Slide(Gravity.BOTTOM).apply {
        duration = DEFAULT_ANIMATION_DURATION
    }

}
