/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.phenixrts.suite.groups.R

// TODO: Needs to be refactored and reimplemented
class ParticipantsListFragment : BaseFragment() {

    private val listAdapter by lazy {
        /*ParticipantsListAdapter(
            participantsViewModel.roomParticipants,
            previewViewModel.participantInVideoPreview
        )*/
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?) =
        inflater.inflate(R.layout.fragment_participants, container, false)!!

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        //participantsList.adapter = listAdapter
    }
}
