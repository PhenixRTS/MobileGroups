/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.lifecycle.Observer
import com.phenixrts.suite.groups.common.extensions.*
import com.phenixrts.suite.groups.databinding.FragmentMembersBinding
import com.phenixrts.suite.groups.models.RoomMember
import com.phenixrts.suite.groups.ui.adapters.MemberListAdapter
import timber.log.Timber

class MemberFragment : BaseFragment(), MemberListAdapter.OnMemberListener {

    private lateinit var binding: FragmentMembersBinding

    private val adapter by lazy { MemberListAdapter(viewModel, getSurfaceView(), this) }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        binding = FragmentMembersBinding.inflate(inflater)
        binding.lifecycleOwner = this
        binding.memberList.adapter = adapter

        viewModel.getRoomMembers().observe(viewLifecycleOwner, Observer { members ->
            Timber.d("Member adapter updated ${members.size} $members")
            adapter.members = members
        })
        return binding.root
    }

    override fun onDestroy() {
        super.onDestroy()
        adapter.dispose()
    }

    override fun onMemberClicked(roomMember: RoomMember) {
        Timber.d("Member clicked: $roomMember")
        viewModel.pinActiveMember(roomMember)
    }

}
