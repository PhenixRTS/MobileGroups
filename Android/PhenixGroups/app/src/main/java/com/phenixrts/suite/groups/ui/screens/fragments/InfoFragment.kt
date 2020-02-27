/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import com.phenixrts.suite.groups.databinding.FragmentInfoBinding

const val EXTRA_ROOM_ALIAS = "extraRoomAlias"

class InfoFragment : Fragment() {

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?) =
        FragmentInfoBinding.inflate(inflater).apply {
            roomAlias = arguments?.getString(EXTRA_ROOM_ALIAS, "") ?: ""
            lifecycleOwner = this@InfoFragment
        }.root

}

