/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.lifecycle.Observer
import com.phenixrts.common.RequestStatus
import com.phenixrts.room.Stream
import com.phenixrts.suite.groups.common.extensions.showToast
import com.phenixrts.suite.groups.common.getSubscribeOptions
import com.phenixrts.suite.groups.databinding.FragmentParticipantsBinding
import com.phenixrts.suite.groups.ui.adapters.ParticipantListAdapter
import timber.log.Timber

class ParticipantFragment : BaseFragment(), ParticipantListAdapter.OnParticipant {

    private lateinit var binding: FragmentParticipantsBinding

    private val adapter by lazy { ParticipantListAdapter(viewModel, this) }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        binding = FragmentParticipantsBinding.inflate(inflater)
        binding.lifecycleOwner = this
        binding.participantList.adapter = adapter

        viewModel.getRoomMembers().observe(viewLifecycleOwner, Observer {
            Timber.d("Member adapter updated")
            adapter.data = it
        })
        return binding.root
    }

    override fun onParticipantClicked(stream: Stream?, isSelf: Boolean) {
        launch {
            viewModel.stopMediaRenderer()
            if (isSelf) {
                Timber.d("Self clicked")
                viewModel.startMediaPreview(getSurfaceHolder())
            }
            else if (stream != null) {
                val options = getSubscribeOptions(getSurfaceHolder())
                val status = viewModel.subscribeToMemberStream(stream, options)
                Timber.d("Subscribed to member media: $status")
                if (status.status != RequestStatus.OK) {
                    showToast(status.message)
                }
            } else {
                showToast("Failed to load member stream")
                viewModel.startMediaPreview(getSurfaceHolder())
            }
        }
    }

}
