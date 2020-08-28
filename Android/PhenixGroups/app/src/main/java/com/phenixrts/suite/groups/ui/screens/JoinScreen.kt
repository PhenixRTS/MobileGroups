/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
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
import com.phenixrts.suite.groups.common.extensions.joinRoom
import com.phenixrts.suite.groups.common.extensions.showToast
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment
import kotlinx.android.synthetic.main.fragment_join.view.*
import timber.log.Timber

class JoinScreen : BaseFragment() {

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?) =
        inflater.inflate(R.layout.fragment_join, container, false)!!

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        view.join_room_dismiss_button.setOnClickListener {
            dismissFragment()
        }
        view.join_room_button.setOnClickListener {
            view.join_room_code_input.text.toString().takeIf { it.isNotBlank() }?.let { code ->
                Timber.d("Join Room clicked: $code")
                joinRoom(viewModel, code, preferenceProvider.getDisplayName())
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
