/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.activecall

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.models.UserSettings
import com.phenixrts.suite.groups.viewmodels.RoomViewModel
import kotlinx.android.synthetic.main.group_call_fragment.*

class GroupCallScreen : Fragment() {

    private val roomViewModel: RoomViewModel by viewModels({ activity!! })
    private val userSettings: UserSettings by viewModels({ activity!! })

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        roomViewModel.startCall(userSettings)
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.group_call_fragment, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        servicePager.adapter = GroupCallScreenPageAdapter(resources, childFragmentManager)
    }

    override fun onDestroy() {
        roomViewModel.endCall()
        super.onDestroy()
    }
}