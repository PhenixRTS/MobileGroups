/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.phenixrts.suite.groups.databinding.FragmentMembersBinding
import com.phenixrts.suite.groups.ui.adapters.MemberListAdapter
import com.phenixrts.suite.phenixcore.common.launchUI
import com.phenixrts.suite.phenixcore.repositories.models.PhenixEvent
import timber.log.Timber

class MemberFragment : BaseFragment() {

    private lateinit var binding: FragmentMembersBinding

    private val adapter by lazy {
        MemberListAdapter(onMemberClicked = { member ->
            viewModel.selectMember(member.id, !member.isSelected)
        }, onMemberDrawn = { member, imageView ->
            if (member.isSelf) {
                phenixCore.previewOnImage(imageView)
            } else {
                phenixCore.renderOnImage(member.id, imageView)
            }
        })
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        binding = FragmentMembersBinding.inflate(inflater, container, false)
        binding.lifecycleOwner = viewLifecycleOwner
        binding.memberList.adapter = adapter
        binding.memberList.itemAnimator?.changeDuration = 0
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        launchUI {
            viewModel.members.collect { members ->
                Timber.d("Member adapter updated ${members.size} $members")
                adapter.members = members
            }
        }

        launchUI {
            phenixCore.onEvent.collect { event ->
                if (event == PhenixEvent.CAMERA_FLIPPED) {
                    adapter.notifyItemChanged(0)
                }
            }
        }
    }
}
