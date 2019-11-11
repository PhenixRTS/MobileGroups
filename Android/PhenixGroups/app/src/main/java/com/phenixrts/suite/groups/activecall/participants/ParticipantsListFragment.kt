/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.activecall.participants

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.viewmodels.RoomViewModel
import kotlinx.android.synthetic.main.group_call_participants_fragment.*

class ParticipantsListFragment : Fragment() {

    private val roomViewModel: RoomViewModel by viewModels({ activity!! })

    private val listAdapter by lazy {
        ParticipantsListAdapter(
            roomViewModel.roomParticipants,
            roomViewModel.activeParticipant
        )
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.group_call_participants_fragment, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        participantsList.adapter = listAdapter
    }

}